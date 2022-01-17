defmodule ExUps.ParsersTest do
  use ExUnit.Case

  alias ExUps.Parsers

  test "parse begin list" do
    assert {:ok, [:begin, :ups], "", _, _, _} = Parsers.parse_line("BEGIN LIST UPS\n")
  end

  test "begin list vars" do
    assert {:ok, [:begin, :var, "ups"], "", _, _, _} = Parsers.parse_line("BEGIN LIST VAR ups\n")
  end

  test "short line gives error and entire line back" do
    assert {:error, _, "BEGIN LIST V", _, _, _} = Parsers.parse_line("BEGIN LIST V")
  end

  test "parse line with leftovers" do
    assert {:ok, [:var, "ups", "this.that", "HELLO!\\"], "leftovers", _, _, _} =
             Parsers.parse_line("VAR ups this.that \"HELLO!\\\\\"\nleftovers")
  end
end
