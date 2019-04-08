defmodule Lnx.LocalFeatures do
  defstruct [
    :option_data_loss_protect,
    :initial_routing_sync,
    :option_upfront_shutdown_script,
    :gossip_queries
  ]

  def valid_values() do
    %{
      option_data_loss_protect: [:unsupported, :supported, :required],
      initial_routing_sync: [true, false],
      option_upfront_shutdown_script: [:unsupported, :supported, :required]
    }
  end
end

defmodule Lnx.GlobalFeatures do
  defstruct []
end
