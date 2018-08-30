defmodule Cqpdemo.MsgHandler do
  @moduledoc """
  为自定义插件模块提供消息过滤的宏
  NOTE: 目前使用该套宏会导致插件调试过程中错误提示不清晰
  """
  defmacro __using__(_) do
    module = __CALLER__.module
    quote do
      Module.register_attribute unquote(module), :plugs, accumulate: true
      import Cqpdemo.MsgHandler
      @before_compile Cqpdemo.MsgHandler
    end
  end

  defmacro observe(name, values) do
    module = __CALLER__.module
    quote do
      Module.put_attribute unquote(module), :plugs, Macro.escape({:observe, unquote(name), unquote(values)})
    end
  end

  defmacro ignore(name, values) do
    module = __CALLER__.module
    quote do
      Module.put_attribute unquote(module), :plugs, Macro.escape({:ignore, unquote(name), unquote(values)})
    end
  end

  defmacro filtered(do: block) do
    Module.put_attribute __CALLER__.module, :handle, block
    quote do
      def handle_msg(msg, state) do
        case validate_msg(msg) do
          false -> state
          true ->
            {new_state, _} = Code.eval_quoted(@handle, [msg: msg, state: state])
            new_state
        end
      end
    end
  end

  defmacro __before_compile__(env) do
    plugs = Module.get_attribute(env.module, :plugs)
    quote do
      def validate_msg(msg) do
        unquote(plugs)
        |> Enum.map(&(validate(&1, msg)))
        |> Enum.all?(&(&1))
      end
    end
  end

  def validate({type, name, values}, msg) do
    case type do
      :observe ->
        validate_observe(msg, name, values)
      :ignore ->
        validate_ignore(msg, name, values)
    end
  end

  def validate_observe(msg, name, values) do
    msg_value = get_in(msg, name)
    values
    |> Enum.map(&(&1 == msg_value))
    |> Enum.any?(&(&1))
  end

  def validate_ignore(msg, name, values) do
    msg_value = get_in(msg, name)
    values
    |> Enum.map(&(&1 != msg_value))
    |> Enum.all?(&(&1))
  end

end

