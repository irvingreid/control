# Manage the TCP connection to upsd

defmodule ExUps.Connection do
  use Connection

  @moduledoc """
  Send commands to upsd over TCP, asynchronously parse and process the results.
  Supports only the bits of the upsd protocol I need for my home monitoring application.
  """
  alias ExUps.Parsers
  require OpenTelemetry.Tracer, as: Tracer

  @spec send(ExUps.Connection, iodata()) :: any
  def send(conn, data), do: Connection.call(conn, {:send, [data | '\n']})

  @spec recv(any, any, any) :: any
  def recv(conn, bytes, timeout \\ 3000) do
    Connection.call(conn, {:recv, bytes, timeout})
  end

  # external API for process lifecycle
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(opts) do
    with {:ok, conf} = Application.fetch_env(:control, ExUps.Connection) do
      Connection.start_link(__MODULE__, {conf[:host], conf[:port], opts, conf[:timeout]},
        name: __MODULE__
      )
    else
      err -> err
    end
  end

  @spec close(any) :: any
  def close(conn), do: Connection.call(conn, :close)

  @type state :: %{
          host: String.t(),
          port: integer,
          opts: [any()],
          timeout: integer,
          sock: any(),
          buffer: String.t(),
          category: [any()],
          accum: [[any()]]
        }

  def init({host, port, opts, timeout}) do
    s = %{
      host: host,
      port: port,
      opts: opts,
      timeout: timeout,
      sock: nil,
      buffer: "",
      category: [],
      accum: []
    }

    {:connect, :init, s}
  end

  # internal
  def connect(
        _,
        %{sock: nil, host: host, port: port, opts: opts, timeout: timeout} = s
      ) do
    options = [active: :once] ++ opts
    IO.puts("connect: #{inspect(host)}:#{port} (#{inspect(options)}), timeout: #{timeout}")

    case :gen_tcp.connect(host, port, options, timeout) do
      {:ok, sock} ->
        {:ok, %{s | sock: sock}}

      {:error, _} ->
        {:backoff, 1000, s}
    end
  end

  def disconnect(info, %{sock: sock} = s) do
    :ok = :gen_tcp.close(sock)

    case info do
      {:close, from} ->
        Connection.reply(from, :ok)

      {:error, :closed} ->
        :error_logger.format('Connection closed~n', [])

      {:error, reason} ->
        reason = :inet.format_error(reason)
        :error_logger.format('Connection error: ~s~n', [reason])
    end

    {:connect, :reconnect, %{s | sock: nil}}
  end

  def handle_call({:send, _} = message, whatever, %{sock: nil} = s) do
    {:ok, state} = connect(:reconnect, s)
    handle_call(message, whatever, state)
  end

  def handle_call({:send, data}, _, %{sock: sock} = s) do
    case :gen_tcp.send(sock, data) do
      :ok ->
        {:reply, :ok, s}

      {:error, _} = error ->
        {:disconnect, error, error, s}
    end
  end

  def handle_call(_, _, %{sock: nil} = s) do
    {:reply, {:error, :closed}, s}
  end

  def handle_call({:recv, bytes, timeout}, _, %{sock: sock} = s) do
    case :gen_tcp.recv(sock, bytes, timeout) do
      {:ok, _} = ok ->
        {:reply, ok, s}

      {:error, :timeout} = timeout ->
        {:reply, timeout, s}

      {:error, _} = error ->
        {:disconnect, error, error, s}
    end
  end

  def handle_call(:close, from, s) do
    {:disconnect, {:close, from}, s}
  end

  def handle_info({:tcp, socket, msg}, %{buffer: buf, sock: socket} = state) do
    # Allow the socket to send us the next message.
    :inet.setopts(socket, active: :once)
    process_nut_message(buf <> to_string(msg), state)
  end

  def handle_info({:tcp_closed, socket}, state) do
    :ok = :gen_tcp.close(socket)
    {:noreply, %{state | sock: nil}}
  end

  # janky state machine - as long as our buffer has a newline in it, run it through the parser
  # and add it to our state
  defp process_nut_message("", s) do
    {:noreply, %{s | buffer: ""}}
  end

  defp process_nut_message(buffer, s) do
    handle_parse(Parsers.parse_line(buffer), s)
  end

  defp handle_parse({:ok, line, rest, _, _, _}, s) do
    newstate = handle_line(line, s)
    process_nut_message(rest, newstate)
  end

  defp handle_parse({:error, message, buffer, _, _, _}, s) do
    IO.puts("hp err #{message}")
    # For now, pretend there are no syntax errors and wait for more data
    {:noreply, %{s | buffer: buffer}}
  end

  defp handle_line([:begin | category], %{category: []} = s) do
    %{s | category: category, accum: []}
  end

  defp handle_line([:var | _] = v, %{accum: accum} = s) do
    %{s | accum: [v | accum]}
  end

  defp handle_line([:end, :var, ups_name], %{category: [:var, ups_name], accum: accum} = s) do
    Tracer.add_event("ups-status", [
      {:ups_name, ups_name} | Enum.map(accum, fn [:var, _, key, val] -> {key, val} end)
    ])

    IO.puts(
      inspect([{:ups_name, ups_name} | Enum.map(accum, fn [:var, _, key, val] -> {key, val} end)])
    )

    %{s | category: [], accum: []}
  end

  @spec handle_line([any()], state) :: state
  defp handle_line([:end | category] = line, %{category: category, accum: accum} = s) do
    # credo:disable-for-lines:2 Credo.Check.Warning.IoInspect
    IO.inspect(line)
    Enum.each(accum, &IO.inspect/1)
    %{s | category: [], accum: []}
  end
end
