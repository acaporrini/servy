defmodule Recurse do
  def loopy([head | tail], list) do
    IO.puts "Head: #{head} Tail: #{inspect(tail)}"
    list = list ++ [(head * 3)]
    IO.inspect list
    loopy(tail, list)
  end

  def loopy([], list), do: list
end 
