# Control

Control runs on a Raspberry Pi 4b (thanks, https://www.pishop.ca/!) in my wiring cabinet.

Various purposes:
- get more familiar with Phoenix and LiveView
- try out some OpenTelemetry with Honeycomb and/or text logs
- provide a UI for a few bits of home control

## Local links

The Pi also hosts the management server and web UI for all the networking gear, so we'll provide a
handy link to that.

## UPS status

The core network infrastructure (cable modem, firewall, switch, and WiFi APs) are all powered
through a CyberPower UPS. One of the main reasons for getting the Pi is to monitor the UPS (over USB)
because it gets line power from a Ground Fault Interruptor protected circuit that trips from time to time.

Current harebrained scheme is to have `upsd` from the Network UPS Tools send events to my https://www.honeycomb.io
developer account for observability practice, and have either Honeycomb or `upsmon` send events to my PagerDuty
developer account when it needs attention.

The Phoenix app might get involved in remote controlling some of this, but for starters I'll have it display
the status.

## Phoenix Default README stuff

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
