defmodule Cqpdemo.Follow do
  use Cqpdemo.View
  # state:
  # %{
  #   group_id:{
  #     repeat: [],
  #     old_msgs: []
  #   }
  # }
  observe ["message_type"], ["group"]
  observe ["sub_type"], ["normal"]
  ignore  ["user_id"], [11111111111, 22222222222]#群里有其他机器人的话还是过滤其消息为好……

  filtered do
    group_id = msg["group_id"]
    user_id = msg["user_id"]
    # 获取user身份
    role =
      Cqpdemo.Cqpsdk.get_group_member_info(group_id, user_id)
      |> get_in(["data", "role"])
    state =
      case state[group_id] == nil do
        true -> put_in(state, [group_id], %{repeat: [],old_msgs: []})
        false -> state
      end
    rate = 0.3

    case msg["message"] do
      ":follow on" ->
        Cqpdemo.Cqpsdk.send_group_msg(group_id, "风怒复读机注册成功, 复读率#{rate*100}%")
        update_in(state, [group_id, :repeat], &(Enum.uniq [user_id | &1]))
      ":follow off" ->
        Cqpdemo.Cqpsdk.send_group_msg(group_id, "风怒复读机已取消")
        update_in(state, [group_id, :repeat], &(List.delete(&1, user_id)))
      ":follow ruin" when role in ["owner", "admin"] ->
        Cqpdemo.Cqpsdk.send_group_msg(group_id, "风怒复读机已摧毁")
        put_in(state, [group_id, :repeat], [])
      ":" <> _ ->
        state
      content ->
        #IO.inspect content
        if Cqpdemo.Util.rate(rate) and user_id in state[group_id].repeat do
          Cqpdemo.Cqpsdk.send_group_msg(group_id, content)
        end
        state
    end
  end
end

