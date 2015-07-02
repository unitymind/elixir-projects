defmodule EtsRegistry.Server do
  use GenServer

  @table_prefix __MODULE__

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    EtsRegistry.Recovery.unstash()
    {:ok, []}
  end

  def create(name) do
    GenServer.call(__MODULE__, {:create, name})
  end

  def heir_recovery() do
      GenServer.call(__MODULE__, :heir_recovery)
  end

  def handle_call({:create, name}, {recover_to, _reference}, state) do
    case lookup_table(name) do
      {:error, :not_found} -> {:reply, :ok, table(name) |> create(state, recover_to)}
      {:ok, tab} -> {:reply, {:error, :already_created}, state}
    end
  end

  def handle_call(:heir_recovery, {recover_to, _reference}, state) do
    # Ensure that we update heir for ETS-table under the same Supervisor
    if (Process.info(self())[:links] == Process.info(recover_to)[:links]) do
      Enum.each(state, &(:ets.setopts(&1, {:heir, recover_to, Process.info(self())[:links]})))
      {:reply, :ok, state}
    else
      {:reply, {:error, :not_permitted}, state}
    end
  end

  def handle_call({:add, table, key, value}, _, state) do

  end

  def handle_call({:update, table, key, value}, _, state) do

  end

  def handle_call({:get, table, key}, _, state) do

  end

  def handle_call({:remove, table, key}, _, state) do

  end

  def handle_call({:drop, table}, _, state) do

  end

  @spec create(String.t, EtsRegistry.state, pid) :: EtsRegistry.state
  def create(table, state, recover_to) do
    state ++ [:ets.new(table, [:private, :named_table, {:heir, recover_to, Process.info(self())[:links]}])]
  end

  @spec table(String.t) :: atom
  def table(name) do
    String.to_atom("#{@table_prefix}.#{name}")
  end

  @spec lookup_table(String.t) :: {:ok, :ets.tab} | {:error, :not_found}
  def lookup_table(name) do
    if table(name) in :ets.all do
      {:ok, table(name)}
    else
      {:error, :not_found}
    end
  end

  use EtsRegistry.HandleTransfer
  use EtsRegistry.Common
end