defmodule Cqpdemo.Util do
  @doc """
  根据percent随机返回true, false
  用于群机器人的频率控制
  """
  def rate(percent) do
    << a :: 32, b :: 32, c :: 32 >> = :crypto.strong_rand_bytes(12)
    :random.seed({a,b,c})
    random_num = :random.uniform(10000)
    random_num < 10000 * percent
  end
end
