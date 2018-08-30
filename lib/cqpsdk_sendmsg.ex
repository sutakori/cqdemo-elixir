defmodule Cqpdemo.CqpsdkSendmsg do
  @moduledoc """
  通过websocket向http api传递请求
  请求函数在cqpsdk.ex中定义，通过调用def_msg宏实现
  """
  def send_msg(type, params \\ []) do
    api_socket = Socket.Web.connect! "127.0.0.1", Application.get_env(:cqpdemo, :apiport), path: "/api"
    data = Poison.encode!(
      %{
        "action" => Atom.to_string(type),
        "params" => params |> Enum.reduce(%{}, fn ({key, val},acc)->Map.put(acc,key,val) end)
      }
    )
    api_socket |> Socket.Web.send!({:text, data})
    api_socket
    |> Socket.Web.recv!
    |> case do
         {:text, msg} -> msg
       end
    |> Poison.Parser.parse!
  end

  @doc """
  def_msg send_private_msg(user_id, message)
  ======>
  def send_private_msg(user_id, message) do
    api_socket = Socket.Web.connect! "127.0.0.1", 6700, path: "/api"
    data = Poison.encode!(
      %{
        "action" => "send_private_msg",
        "params" => %{
          "user_id": user_id,
          "message": message
        }
      }
    )
    api_socket |> Socket.Web.send!({:text, data})
    api_socket
    |> Socket.Web.recv!
    |> case do
         {:text, msg} -> msg
       end
    |> Poison.Parser.parse!
  end
  """
  defmacro def_msg(head) do
    quote bind_quoted: [
      head: Macro.escape(head, unquote: true),
    ] do
      {msg_type, args_ast} = Cqpdemo.CqpsdkSendmsg.name_and_args(head)
      arg_names = for i <- args_ast do
        {name, _, _} = i
        name
      end
      def unquote(head) do
        Cqpdemo.CqpsdkSendmsg.send_msg(unquote(msg_type), Enum.zip(unquote(arg_names), unquote(args_ast)))
      end
    end
  end

  def name_and_args({:when, _, [short_head | _]}) do
    name_and_args(short_head)
  end

  def name_and_args(short_head) do
    Macro.decompose_call(short_head)
  end
end
