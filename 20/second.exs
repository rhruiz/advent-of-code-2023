defprotocol Pulse do
  def handle(module, signal)
end

defmodule WeHaveSand do
  defexception message: "We have sand"
end

defimpl Pulse, for: Any do
  def handle(_, _), do: :error

  defmacro __deriving__(module, _struct, _options)  do
    debug =
      if "-d" in System.argv() do
        quote do
          IO.puts("#{inspect(from)}: -#{level}-> #{inspect(module)}")
        end
      else
        quote do
        end
      end

    quote do
      defimpl Pulse, for: unquote(module) do
        def handle(module, {from, level} = signal) do
          unquote(debug)
          unquote(module).handle(module, signal)
        end
      end
    end
  end
end

defmodule Halter do
  @derive [Pulse]
  defstruct [on: 0]

  def init(:ok), do: %__MODULE__{}
  def init(on), do: %__MODULE__{on: on}

  def handle(%{on: on}, {_from, on}), do: raise WeHaveSand
  def handle(me, _), do: {me, []}
end

defmodule Broadcaster do
  @derive [Pulse]
  defstruct connections: []

  def init(connections) do
    %__MODULE__{connections: connections}
  end

  def handle(%__MODULE__{connections: connections} = me, {_from, pulse}) do
    {me, Enum.map(connections, &{&1, pulse})}
  end
end

defmodule FlipFlop do
  @derive [Pulse]
  defstruct connections: [], state: 0

  def init(connections) do
    %__MODULE__{connections: connections}
  end

  def handle(me, {_from, 1}) do
    {me, []}
  end

  def handle(%__MODULE__{} = me, {_from, 0}) do
    me = %{me | state: Integer.mod(me.state + 1, 2)}

    {me, Enum.map(me.connections, &{&1, me.state})}
  end
end

defmodule Conjunction do
  @derive [Pulse]
  defstruct connections: [], inputs: %{}

  def init({connections, inputs}) do
    %__MODULE__{connections: connections, inputs: Enum.into(inputs, %{}, &{&1, 0})}
  end

  def handle(%__MODULE__{} = me, {from, pulse}) do
    me = %{me | inputs: Map.put(me.inputs, from, pulse)}

    output = if(Enum.all?(me.inputs, &match?({_, 1}, &1)), do: 0, else: 1)

    {me, Enum.map(me.connections, &{&1, output})}
  end
end

defmodule Simulator do
  def run(modules, []) do
    modules
  end

  def run(modules, [{from, to, signal} | tail]) do
    {new, more_signals} = Pulse.handle(modules[to], {from, signal})
    more_signals = Enum.map(more_signals, fn {receiver, signal} -> {to, receiver, signal} end)

    run(Map.put(modules, to, new), tail ++ more_signals)
  end
end

IO.stream(:stdio, :line)
|> Stream.map(&String.trim/1)
|> Enum.reduce({%{}, %{}}, fn line, {inputs, outputs} ->
  [type_and_name, connections] = String.split(line, " -> ")

  connections = String.split(connections, ", ") |> Enum.map(&String.to_atom/1)

  case type_and_name do
    "broadcaster" = name ->
      name = String.to_atom(name)

      {
        Enum.reduce(connections, inputs, fn c, acc ->
          Map.update(acc, c, [name], &[name | &1])
        end),
        Map.put(outputs, name, {Broadcaster, connections})
      }

    <<"%", name::binary>> ->
      name = String.to_atom(name)

      {
        Enum.reduce(connections, inputs, fn c, acc ->
          Map.update(acc, c, [name], &[name | &1])
        end),
        Map.put(outputs, name, {FlipFlop, connections})
      }

    <<"&", name::binary>> ->
      name = String.to_atom(name)

      {
        Enum.reduce(connections, inputs, fn c, acc ->
          Map.update(acc, c, [name], &[name | &1])
        end),
        Map.put(outputs, name, {Conjunction, connections})
      }
  end
end)
|> then(fn {inputs, outputs} ->
  modules =
    Enum.into(outputs, %{}, fn
      {name, {Conjunction, connections}} ->
        {name, Conjunction.init({connections, inputs[name]})}

      {name, {module, connections}} ->
        {name, module.init(connections)}
    end)
    |> Map.put(:rx, Halter.init(:ok))

  {modules, inputs[:rx]}
end)
|> then(fn {modules, [interesting]} ->
  interesting = Map.keys(modules[interesting].inputs)

  Enum.flat_map(interesting, fn input ->
    modules = Map.put(modules, input, Halter.init(0))

    Stream.unfold(0, &{&1, &1 + 1})
    |> Stream.transform({modules, true}, fn i, {modules, first} ->
      try do
        Simulator.run(modules, [{:button, :broadcaster, 0}])
      else
        modules ->
          {[], {modules, first}}
      rescue
        WeHaveSand ->
          if first do
            {[], {modules, false}}
          else
            {[i], {modules, false}}
          end
      end
    end)
    |> Enum.take(1)
  end)
  |> Enum.reduce(fn a, b -> div(a * b, Integer.gcd(a, b)) end)
  |> IO.inspect()
end)
