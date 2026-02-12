defmodule HrBrandAgent.Integrations.Telegram.Bot do
  @moduledoc """
  Telegram Bot integration using Telegex.
  """
  use GenServer
  require Logger

  alias Telegex.Type

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def send_message(chat_id, text, opts \\ []) do
    GenServer.call(__MODULE__, {:send_message, chat_id, text, opts})
  end

  def get_updates(opts \\ []) do
    GenServer.call(__MODULE__, {:get_updates, opts})
  end

  def search_chats(query, limit \\ 50) do
    GenServer.call(__MODULE__, {:search_chats, query, limit})
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    # Configure Telegex
    token = Application.get_env(:hr_brand_agent, :telegram)[:bot_token]
    
    if token do
      Application.put_env(:telegex, :token, token)
      Application.put_env(:telegex, :caller_adapter, Finch)
      
      Logger.info("Telegram Bot initialized")
      {:ok, %{initialized: true, last_update_id: 0}}
    else
      Logger.warning("Telegram Bot token not configured")
      {:ok, %{initialized: false, last_update_id: 0}}
    end
  end

  @impl true
  def handle_call({:send_message, chat_id, text, opts}, _from, %{initialized: true} = state) do
    case Telegex.send_message(chat_id, text, opts) do
      {:ok, message} ->
        {:reply, {:ok, message}, state}
        
      {:error, error} ->
        Logger.error("Failed to send Telegram message: #{inspect(error)}")
        {:reply, {:error, error}, state}
    end
  end

  @impl true
  def handle_call({:send_message, _chat_id, _text, _opts}, _from, state) do
    {:reply, {:error, :not_initialized}, state}
  end

  @impl true
  def handle_call({:get_updates, opts}, _from, %{initialized: true} = state) do
    offset = opts[:offset] || state.last_update_id + 1
    limit = opts[:limit] || 100
    
    case Telegex.get_updates(offset: offset, limit: limit) do
      {:ok, updates} ->
        new_state = 
          if length(updates) > 0 do
            last_id = Enum.max_by(updates, & &1.update_id).update_id
            %{state | last_update_id: last_id}
          else
            state
          end
        
        {:reply, {:ok, updates}, new_state}
        
      {:error, error} ->
        Logger.error("Failed to get Telegram updates: #{inspect(error)}")
        {:reply, {:error, error}, state}
    end
  end

  @impl true
  def handle_call({:get_updates, _opts}, _from, state) do
    {:reply, {:error, :not_initialized}, state}
  end

  @impl true
  def handle_call({:search_chats, _query, _limit}, _from, state) do
    # Bot API doesn't support searching all chats
    # Bots can only access chats where they are members
    {:reply, {:error, :not_supported_by_bot_api}, state}
  end
end
