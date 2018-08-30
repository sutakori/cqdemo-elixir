# Cqpdemo

基于酷q http api(https://github.com/richardchien/coolq-http-api) 实现的elixir 酷q机器人

发送与接收的消息结构请参考http api

## 消息响应的设计

每一个插件作为对接收到的消息进行观察与处理响应的视图，维护根据功能自定义的state，随消息的接收而变化，详见示例代码。

## 文件结构

#### sdk：

cqpsdk_sendmsg.ex 

定义了方便sdk函数定义的def_msg宏，将elixir函数定义结构映射为http api调用。

cqpsdk.ex 

定义酷q elixir sdk函数，仅预先定义了几个常用函数，若需要其他调用请参考http api参照现有定义添加新的调用

#### view：

msg_handler.ex

方便消息过滤的一套宏，注意目前使用该套宏一定程度上会导致调试困难

view.ex

每个自定义插件通过use Cqpdemo.View注册为view

#### main:

cqpdemo.ex

Application入口，调整children变量控制插件启动

#### 其他：

friend.ex learn.ex  功能插件示例

repeat.ex                 消息拉取的示例

