defmodule Volta.LightningMsg do
  @init 16
  @error 17
  @ping 18
  @pong 19

  defmodule UnknownMsg do
    defstruct [:type, :payload]
  end

  defmodule InitMsg do
    defstruct [global_features: <<>>, local_features: <<0>>]
  end

  defmodule ErrorMsg do
    defstruct [:channel_id, :data]
  end

  defmodule PingMsg do
    defstruct [:ping_bytes, :pong_bytes]
  end

  defmodule PongMsg do
    defstruct [:pong_bytes]
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
    %PingMsg{ping_bytes: ignore_len, pong_bytes: pong_bytes}        
  end

  def parse_type(
        @pong,
        <<ignore_len::unsigned-big-size(16), _::bytes-size(ignore_len)>>) do
    %PongMsg{pong_bytes: ignore_len}        
  end

  def parse_type(type, payload) do
    %UnknownMsg{type: type, payload: payload}
  end

  def encode(%InitMsg{} = msg) do
    gflen = byte_size(msg.global_features)
    lflen = byte_size(msg.local_features)
    <<
      @init::unsigned-big-size(16),
      gflen::unsigned-big-size(16), msg.global_features::bytes-size(gflen), 
      lflen::unsigned-big-size(16), msg.local_features::bytes-size(lflen)
    >>
  end

  def encode(%ErrorMsg{} = msg) do
    data_len = byte_size(msg.data)
    <<
      @error::unsigned-big-size(16),
      msg.channel_id::unsigned-big-size(256), 
      data_len::unsigned-big-size(16), 
      msg.data::bytes-size(data_len)
    >>
  end

  def encode(%PingMsg{} = msg) do
    ignore_len = msg.ping_bytes * 8
    <<
      @ping::unsigned-big-size(16),
      msg.pong_bytes::unsigned-big-size(16),
      msg.ping_bytes::unsigned-big-size(16),
      0::size(ignore_len)
    >>
  end

  def encode(%PongMsg{} = msg) do
    ignore_len = msg.pong_bytes * 8
    <<
      @pong::unsigned-big-size(16),
      msg.pong_bytes::unsigned-big-size(16), 
      0::size(ignore_len)
    >>
  end

end
