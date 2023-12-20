defprotocol Pulse do
  def handle(module, signal)
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
          Counter.increment(level)
          unquote(debug)
          unquote(module).handle(module, signal)
        end
      end
    end
  end
end

defmodule Counter do
  use Agent

  def start_link() do
    Agent.start_link(fn -> {0, 0} end, name: __MODULE__)
  end

  def increment(0) do
    Agent.update(__MODULE__, fn {low, high} ->
      {low + 1, high}
    end)
  end

  def increment(1) do
    Agent.update(__MODULE__, fn {low, high} ->
      {low, high + 1}
    end)
  end

  def get() do
    Agent.get(__MODULE__, & &1)
  end
end

defmodule Inert do
  @derive [Pulse]
  defstruct []

  def init(_), do: %__MODULE__{}

  if "-o" in System.argv() do
    def handle(me, {_from, signal}) do
      IO.puts([IO.ANSI.green(), "#{signal}", IO.ANSI.reset()])

      {me, []}
    end
  else
    def handle(me, {_from, _signal}) do
      {me, []}
    end
  end
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
  Enum.into(outputs, %{}, fn
    {name, {Conjunction, connections}} ->
      {name, Conjunction.init({connections, inputs[name]})}

    {name, {module, connections}} ->
      {name, module.init(connections)}
  end)
  |> then(fn outputs ->
    inputs
    |> Map.keys()
    |> Enum.reduce(outputs, fn name, inputs ->
      if Map.has_key?(inputs, name) do
        inputs
      else
        Map.put(inputs, name, Inert.init(:ok))
      end
    end)
  end)
end)
|> then(fn modules ->
  Counter.start_link()

  1..1000
  |> Enum.reduce(modules, fn _, modules ->
      Simulator.run(modules, [{:button, :broadcaster, 0}])
  end)

  if "-d" in System.argv() || "-v" in System.argv() do
    Counter.get() |> IO.inspect(label: "counter")
  end

  {low, high} = Counter.get()
  IO.inspect(low * high)
end)
