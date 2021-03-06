defmodule EtsRegistry do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children =
      # Define workers and child supervisors to be supervised
      if (Mix.env() == :dev) do
        [worker(EtsRegistry.Sweeper, [[debug: [:trace], name: EtsRegistry.Sweeper]]),
        worker(EtsRegistry.Recovery, [[debug: [:trace], name: EtsRegistry.Recovery]]),
        worker(EtsRegistry.Server, [[debug: [:trace], name: EtsRegistry.Server]])]
      else
        [worker(EtsRegistry.Sweeper, [[name: EtsRegistry.Sweeper]]),
        worker(EtsRegistry.Recovery, [[name: EtsRegistry.Recovery]]),
        worker(EtsRegistry.Server, [[name: EtsRegistry.Server]])]
      end


    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EtsRegistry.Supervisor]
    Supervisor.start_link(children, opts)
  end

  use EtsRegistry.Client
end
