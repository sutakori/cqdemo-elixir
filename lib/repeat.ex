defmodule Cqpdemo.Repeat do
  @moduledoc """
  随机发一个数字给命令发出人
  5秒内复读且回复正确判定成功， 否则失败
  作为fetch_msg的使用演示
  """

  use Cqpdemo.View
  require Logger

  # state:
  # %{
  #   group_id => %{
  #     user_id => "xxx"
  #   }
  # }

  def get_caller_msg(group_id, user_id) do
    msg = Cqpdemo.Cqpsdk.fetch_msg(self())
    # 对消息进行过滤
    case msg do
      %{
        "message_type" => "group",
        "group_id" => ^group_id,
        "user_id" => ^user_id
      } -> msg["message"]
      _ -> get_caller_msg(group_id, user_id)
    end
  end

  def wait_repeat(state, group_id, user_id) do
    to_match = Integer.to_string state[group_id][user_id]
    #NOTE: 主动获取消息超时的处理
    #TODO: 考虑一般场景下延时的需求是对于一次匹配的消息接收，
    #      延时的处理没有在sdk中实现，而是要求用户处理
    response_task = Task.async(fn -> get_caller_msg(group_id, user_id) end)
    response =
      case Task.yield(response_task, 5000) do
        {:ok, res} -> res
        _ -> "nomsg"
      end

    if response == to_match do
      Cqpdemo.Cqpsdk.send_group_msg(group_id, "复读成功")
    else
      Cqpdemo.Cqpsdk.send_group_msg(group_id, "复读失败")
    end
  end

  observe ["message_type"], ["group"]
  observe ["sub_type"], ["normal"]

  filtered do
    require Logger
    import Cqpdemo.Repeat

    group_id = msg["group_id"]
    state =
      case state[group_id] == nil do
        true -> put_in(state, [group_id], %{})
        false -> state
      end

    case {msg["user_id"], msg["message"]} do
      {user_id, ":repeat"} ->
        IO.inspect user_id
        num = :random.uniform(10000)
        Cqpdemo.Cqpsdk.send_group_msg(group_id, Integer.to_string num)
        state = put_in(state, [group_id, user_id], num)
        #开一个线程对当前state做出反应
        spawn fn -> wait_repeat(state, group_id, user_id) end
        #继续
        state = update_in(state, [group_id], &(Map.delete(&1, user_id)))
      _ ->
        state
    end
  end
end
