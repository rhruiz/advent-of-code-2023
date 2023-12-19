defmodule LeParser do
  defmacro __using__(_) do
    IO.stream(:stdio, :line)
    |> Stream.map(&String.trim/1)
    |> Stream.take_while(&(&1 != ""))
    |> Enum.map(fn line ->
      [name, body] = String.split(line, "{")
      [body | _] = String.split(body, "}")
      name = String.to_atom(name)
      tests = String.split(body, ",")

      quote do
        def perform(unquote(name), part) do
          unquote(to_if(tests))
        end
      end
    end)
  end

  def to_if(["A" | _]), do: true

  def to_if(["R" | _]), do: false

  def to_if([<<workflow::binary-size(2)>> | _]) do
    quote do
      apply(__MODULE__, :perform, [unquote(String.to_atom(workflow)), part])
    end
  end

  def to_if([<<workflow::binary-size(3)>> | _]) do
    quote do
      apply(__MODULE__, :perform, [unquote(String.to_atom(workflow)), part])
    end
  end

  def to_if([test | tail]) do
      [<<category::binary-size(1), op::binary-size(1), right::binary>>, destination] =
        String.split(test, ":")

      category = String.to_atom(category)
      op = String.to_atom(op)
      right = String.to_integer(right)

      case destination do
        <<_::binary-size(1)>> ->
          quote do
            if apply(Kernel, unquote(op), [part[unquote(category)], unquote(right)]) do
              unquote(to_if([destination]))
            else
              unquote(to_if(tail))
            end
          end

        _ ->
          quote do
            if apply(Kernel, unquote(op), [part[unquote(category)], unquote(right)]) do
              perform(unquote(String.to_atom(destination)), part)
            else
              unquote(to_if(tail))
            end
          end
      end
  end
end

defmodule PartSorter do
  use LeParser
end

IO.stream(:stdio, :line)
|> Enum.map(fn line ->
  {code, []} = Code.eval_string("%#{String.replace(line, "=", ": ")}")
  code
end)
|> Enum.filter(fn part -> PartSorter.perform(:in, part) end)
|> Enum.reduce(0, fn part, acc ->
  Map.values(part) |> Enum.sum() |> Kernel.+(acc)
end)
|> IO.inspect()
