defmodule Cqpdemo do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # 选择开启的插件
    children = [
      {Cqpdemo.Cqpsdk, []},
      {Cqpdemo.Follow, []},
      # {Cqpdemo.Help, []},
      {Cqpdemo.Friend, []},
      {Cqpdemo.Learn, []},
      # {Cqpdemo.Content, []},
      # {Cqpdemo.Say, []}
      # {Cqpdemo.Test, []},
      {Cqpdemo.Repeat, []},
      #Supervisor.Spec.worker(CodeReloader.Server, [])
    ]

    opts =  [strategy: :one_for_one, name: Cqpdemo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
