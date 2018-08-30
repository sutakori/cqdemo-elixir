defmodule Cqpdemo.Learn do
  @moduledoc """
  学习对话，句子中包含学习子句的话，返回学习到的句子：
  例：
                   :learn aaa bbb
  学习成功
                   wwwaaawww
  bbb
                   :forget aaa
  嘤嘤嘤，我再也不响应aaa了
  """
  use Cqpdemo.View
  # state:
  # %{
  #   group_id:{
  #     learned:{
  #     }
  #   }
  # }
  observe ["message_type"], ["group"]
  observe ["sub_type"], ["normal"]
  ignore  ["user_id"], [111111111, 22222222]

  # view的基本使用见friend.ex
  # 此处演示该模式在较复杂一点场景下的使用
  filtered do
    group_id = msg["group_id"]

    state =
      case state[group_id] == nil do
        true -> put_in(state, [group_id], %{learned: %{}})
        false -> state
      end

    case String.split(msg["message"]) do
      [":learn", ":" <> _ | _] ->
        Cqpdemo.Cqpsdk.send_group_msg(group_id, "句子不能以:开头")
        state
      [":learn", _ | []] ->
        Cqpdemo.Cqpsdk.send_group_msg(group_id, "格式错误，句子间要有空格")
        state
      [":learn", key | contents]->
        if String.length(key) < 2 do
          Cqpdemo.Cqpsdk.send_group_msg(group_id, "句子太短了，请超过两个字符")
          state
        else
          Cqpdemo.Cqpsdk.send_group_msg(group_id, "学习成功")
          update_in(state, [group_id, :learned, key], &(
                case &1 do
                  nil -> [Enum.join(contents," ")]
                  _ -> [Enum.join(contents," ") | &1]
                end
              ))
        end
      [":forget", ":" <> _ | _] ->
        state
      [":forget", key | []] ->
        Cqpdemo.Cqpsdk.send_group_msg(group_id, "嘤嘤嘤，我再也不响应#{key}了")
        update_in(state, [group_id, :learned], &(Map.delete(&1, key)))
      [":forget", key | contents] ->
        contentstr = Enum.join(contents," ")
        Cqpdemo.Cqpsdk.send_group_msg(group_id, "嘤嘤嘤，我再也不说#{contentstr}了")
        update_in(state, [group_id, :learned, key], &(List.delete(&1, contentstr)))
      [":" <> _ | _] ->
        state
      keyl ->
        keys = Enum.join(keyl, " ")
        matched =
          state[group_id].learned
          |> Map.to_list
          |> Enum.filter(fn {key, value} -> String.contains?(keys, key) end)
          |> Enum.map(fn {_, values} -> values end)
          |> List.flatten
        if not Enum.empty?(matched) do
          responce = Enum.random(matched)
          Cqpdemo.Cqpsdk.send_group_msg(group_id, responce)
        end
        state
    end
  end
end
