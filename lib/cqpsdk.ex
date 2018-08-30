defmodule Cqpdemo.Cqpsdk do
  @moduledoc """
  酷q elixir sdk主模块
  调用酷q http api， 可通过def_msg宏定义http sdk中提供的接口调用
  http api 详见 https://github.com/richardchien/coolq-http-api
  提供fetch函数用于在自定义插件中主动获取消息
  """
  require Logger
  use GenServer

  def register(mode, pid) do
    GenServer.cast(__MODULE__, {:register, {mode, pid}})
  end

  # 监听event api传来的消息
  def listen(event_socket) do
    event_socket
    |> Socket.Web.recv!
    |> case do
         {:text, msg} -> msg
       end
    |> Poison.Parser.parse!
    |> publish
    listen(event_socket)
  end

  def publish(msg) do
    GenServer.cast(__MODULE__, {:publish, msg})
  end

  ##
  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    event_socket = Socket.Web.connect! "127.0.0.1", Application.get_env(:cqpdemo, :apiport), path: "/event"
    spawn fn ->
      listen(event_socket)
    end
    {:ok, []}
  end

  def handle_cast({:register, {mode, from}}, state) do
    state =
      case not {mode, from} in state do
        true -> [{mode, from} | state]
        false -> state
      end
    IO.inspect state
    {:noreply, state}
  end


  def handle_cast({:send, to, msg}, state) do
    GenServer.cast(to, {:msg, msg})
    {:noreply, state}
  end

  def handle_cast({:publish, msg}, state) do
    # 取消已结束的fetch
    state = Enum.filter(state, fn
      {:fetch, from}->Process.alive?(from)
      _ -> true
    end)
    for sub <- state do
      case sub do
        {:view, from} ->
          GenServer.cast(__MODULE__, {:send, from, msg})
        {:fetch, from} ->
          send from, {:fetched, from, msg}
      end
    end

    {:noreply, state}
  end

  @doc """
  主动获取消息，使用样例见sddingmei.ex
  ## Parameters
    - pid: 请求消息获取的进程id
  """
  def fetch_msg(pid) do
    register(:fetch, pid)
    receive do
      {:fetched, ^pid, msg} -> msg
    #after
    #  2000 -> :nomsg
    end
  end

  # 定义所需的http api函数
  import Cqpdemo.CqpsdkSendmsg

  # 发送私聊消息
  def_msg send_private_msg(user_id, message)
  # 发送群消息
  def_msg send_group_msg(group_id, message)
  # 群禁言
  def_msg set_group_ban(group_id, user_id, duration)
  #设置群名片
  def_msg set_group_card(group_id, user_id, card)

  #获取群成员信息
  def_msg get_group_member_info(group_id, user_id)
  def_msg get_group_member_info(group_id, user_id, no_cache)
end
