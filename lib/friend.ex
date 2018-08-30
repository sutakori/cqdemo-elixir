defmodule Cqpdemo.Friend do
  # 随机复读

  use Cqpdemo.View
  # 针对功能自定义的state格式
  # state:
  # %{groups: [group_id]}

  # 接收到的消息格式为：
  # {
  #   "xxx": "xxxxx",
  #   "xxx": "xxxxx",
  #   ...
  # }
  observe ["message_type"], ["group"]           # 消息"message_type"键值为"group"时才接受，否则过滤掉
  observe ["sub_type"], ["normal"]
  ignore  ["user_id"], [111111111, 222222222]   # 消息"user_id"键值为11111111或22222222时过滤掉

  # 定义过滤项后调用filter宏隐式定义handle_msg/2
  # msg与state变量能直接使用
  # msg为接收到的消息，state为该插件自定义的状态
  # NOTE: 函数返回新的state, View会进行管理
  # 以下为消息处理推荐写法
  filtered do
    # 提取消息中需要使用的部分
    # 因为以及通过过滤， group_id键一定存在
    group_id = msg["group_id"]

    # state骨架的初始化
    state =
      case state[:groups] == nil do
        true -> put_in(state, [:groups], [])
        false -> state
      end

    #
    rate = 0.01

    # 分类处理对话
    # NOTE: 注意每条分支都要返回state，即使状态 未改变
    case msg["message"] do
      ":friend on" -> #命令处理
        Cqpdemo.Cqpsdk.send_group_msg(group_id, "复读群友已开启, 复读率#{rate*100}%")
        update_in(state, [:groups], &(Enum.uniq [group_id | &1]))
      ":friend off" -> #命令处理
        Cqpdemo.Cqpsdk.send_group_msg(group_id, "复读群友已关闭")
        update_in(state, [:groups], &(List.delete(&1, group_id)))
      ":" <> _ -> #其他机器人命令
        state
      content -> #其他消息
        if Cqpdemo.Util.rate(rate) and group_id in state.groups do
          Cqpdemo.Cqpsdk.send_group_msg(group_id, content)
        end
        state
    end
  end
end
