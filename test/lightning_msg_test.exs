defmodule Volta.LightningMsgTest do
  use ExUnit.Case
  alias Volta.LightningMsg
  alias Volta.LightningMsg.UnknownMsg
  alias Volta.LightningMsg.InitMsg
  alias Volta.LightningMsg.ErrorMsg
  alias Volta.LightningMsg.PingMsg
  alias Volta.LightningMsg.PongMsg

  test "parse unknown message" do
    msg_binary = <<
      3, 233, #type = 1001 
      1,2,3,4 #payload
    >>
    assert LightningMsg.parse(msg_binary) == 
      %UnknownMsg{type: 1001, payload: <<1,2,3,4>>}
  end

  test "parse init message (1 byte)" do
    msg_binary = <<
      0, 16,      #type = 16
      0, 1,       #gflen = 1
      0b10101010, #global features
      0, 1,       #lflen = 1
      0b11111111  #local features
    >>
    assert LightningMsg.parse(msg_binary) == 
      %InitMsg{global_features: <<0b10101010>>, local_features: <<0b11111111>>}
  end

  test "parse init message (2+ bytes)" do
    msg_binary = <<
      0, 16,      #type = 16
      0, 2,       #gflen = 1
      3, 1,       #global features
      0, 3,       #lflen = 1
      3, 2, 1     #local features
    >>
    assert LightningMsg.parse(msg_binary) == 
      %InitMsg{global_features: <<3, 1>>, local_features: <<3, 2, 1>>}
  end

  test "parse error message" do
    msg_binary = <<
      0, 17,      #type = 17
      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4, #channel id = 16909060
      0, 3,       #len = 3
      0, 1, 0     #data
    >>
    assert LightningMsg.parse(msg_binary) == 
    %ErrorMsg{channel_id: 16909060, data: <<0, 1, 0>>}
  end

  test "parse ping msg" do
    msg_binary = <<
      0, 18,      #type = 18
      0, 4,       #num_pong_bytes = 4
      0, 3,       #ignored_len = 3
      0, 0, 0     #ignored
    >>
    assert LightningMsg.parse(msg_binary) == 
      %PingMsg{pong_bytes: 4}
  end

  test "parse pong msg" do
    msg_binary = <<
      0, 19,      #type = 19
      0, 3,       #ignored_len = 3
      0, 0, 0     #ignored
    >>
    assert LightningMsg.parse(msg_binary) == 
      %PongMsg{}
  end
end
