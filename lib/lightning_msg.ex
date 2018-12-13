defmodule Volta.LightningMsg do
  @init 16
  @error 17
  @ping 18
  @pong 19

  defmodule UnknownMsg do
    defstruct [:type, :payload]
  end

  defmodule InitMsg do
    defstruct [:global_features, :local_features]
  end

  defmodule ErrorMsg do
    defstruct [:channel_id, :data]
  end

  defmodule PingMsg do
    defstruct [:pong_bytes]
  end

  defmodule PongMsg do
    defstruct []
  end

  def parse(<<type::unsigned-big-size(16), payload::binary>>) do
    parse_type(type, payload)
  end

  def parse_type(
        @init,
        <<gflen::unsigned-big-size(16), gf::bytes-size(gflen), 
          lflen::unsigned-big-size(16), lf::bytes-size(lflen)>>) do
    %InitMsg{global_features: gf, local_features: lf}
  end

  def parse_type(
        @error,
        <<ch::unsigned-big-size(256), 
          data_len::unsigned-big-size(16), data::bytes-size(data_len)>>) do
    %ErrorMsg{channel_id: ch, data: data}
  end

  def parse_type(
        @ping,
        <<pong_bytes::unsigned-big-size(16),
          ignore_len::unsigned-big-size(16), _::bytes-size(ignore_len)>>) do
    %PingMsg{pong_bytes: pong_bytes}        
  end

  def parse_type(
        @pong,
        <<ignore_len::unsigned-big-size(16), _::bytes-size(ignore_len)>>) do
    %PongMsg{}        
  end

  def parse_type(type, payload) do
    %UnknownMsg{type: type, payload: payload}
  end
end
