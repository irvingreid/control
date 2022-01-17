# Send messages to upsd, parse results

defmodule ExUps.Protocol do
end

defmodule ExUps.Parsers do
  import NimbleParsec

  newline = choice([string("\r\n"), string("\n")])
  name = utf8_string([not: ?\r, not: ?\n, not: ?\s], min: 1)

  escaped_character =
    choice([
      ignore(string("\\")) |> concat(utf8_char([])),
      utf8_char(not: ?", not: ?\\)
    ])

  escaped_value =
    ignore(string("\""))
    |> repeat(escaped_character)
    |> ignore(string("\""))
    |> reduce({List, :to_string, []})

  begin_list_ups =
    replace(string("BEGIN LIST"), :begin) |> replace(string(" UPS"), :ups) |> ignore(newline)

  begin_list_vars =
    replace(string("BEGIN LIST"), :begin)
    |> replace(string(" VAR "), :var)
    |> concat(name)
    |> ignore(newline)

  end_list_vars =
    replace(string("END LIST"), :end)
    |> replace(string(" VAR "), :var)
    |> concat(name)
    |> ignore(newline)

  list_var_line =
    replace(string("VAR "), :var)
    |> concat(name)
    |> ignore(utf8_char([?\s]))
    |> concat(name)
    |> ignore(utf8_char([?\s]))
    |> concat(escaped_value)
    |> ignore(newline)

  defparsec(:list_vars, begin_list_vars |> repeat(list_var_line) |> concat(end_list_vars))

  defparsec(
    :parse_line,
    choice([
      begin_list_ups,
      begin_list_vars,
      end_list_vars,
      list_var_line
    ])
  )
end
