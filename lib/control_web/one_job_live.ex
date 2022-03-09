defmodule ControlWeb.OneJobLive do
  use ControlWeb, :live_view

  def render(assigns) do
    ~H"""
    You have one job: <%= @task %>
    """
  end

  def mount(_params, %{}, socket) do
    task = "get to it"
    {:ok, assign(socket, :task, task)}
  end
end
