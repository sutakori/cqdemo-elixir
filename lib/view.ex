defmodule Cqpdemo.View do
  @moduledoc """
  本demo中处理接收到的消息的方式
  自定义插件通过use Cqpdemo.View注册
  实现handle_msg/2提供消息处理逻辑
  在需要消息过滤的时候推荐通过msg_handler.ex中定义的一套宏完成
  详见friend.ex示例插件
  """

  defmacro __using__(_) do
    quote do
      use GenServer
      use Cqpdemo.MsgHandler
      require Logger
      alias Cqpdemo.Cqpsdk

      def listen_msg() do
        Cqpsdk.register(:view, __MODULE__)
      end

      ##
      def start_link(_args) do
        GenServer.start_link(__MODULE__, [], name: __MODULE__)
      end

      @doc """
      注册view并初始化状态
      """
      def init(_args) do
        listen_msg()
        {:ok, load_state(__MODULE__)}
      end

      @doc """
      接到消息后进行处理
      要求自定义的view实现handle_msg/2
      """
      def handle_cast({:msg, msg}, state) do
        new_state = handle_msg(msg, state)
        if not(new_state == state) do
          Logger.info "[#{__MODULE__} #{inspect new_state}]"
          #IO.inspect new_state
          save_state(__MODULE__,new_state)
        end
        {:noreply, new_state}
      end

      # state persistence
      def save_state(name, state) do
        if not File.exists?("./data") do
          File.mkdir!("./data")
        end
        File.touch! "./data/#{name}"
        case File.open("./data/#{name}",[:write, :utf8]) do
          {:ok, file} ->
            state_encoded = inspect state
            file
            |> IO.write(state_encoded)
            |> File.close
            :ok
          {:error, reason} ->
            IO.puts "Failed when open #{name} for #{reason}"
        end
      end

      def load_state(name) do
        if not File.exists?("./data") do
          File.mkdir!("./data")
        end
        case File.open("./data/#{name}",[:read, :utf8]) do
          {:ok, file} ->
            file
            |> IO.read(:all)
            |> case do
                 {:error, _} -> ""
                 data -> data
               end
            |> Code.eval_string
            |> case do
                 {value, _} -> value
               end
          {:error, _} ->
            %{}
        end
      end
    end
  end
end
