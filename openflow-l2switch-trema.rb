require 'pp'

class L2Switch < Trema::Controller

  def start
    # MACテーブル初期化
    @mactable = {}
  end

  def switch_ready datapath_id
    switch_id = sprintf("%#x", datapath_id)
    puts "Connected Switch: #{switch_id}"
  end

  def packet_in datapath_id, message

    # OpenFlow のフロー追加
    #send_flow_mod_add(
    #  datapath_id,
    #  :idle_timeout => 10,
    #  :hart_timeout => 10,
    #  :match => ExactMatch.from( message ),
    #  :actions => Trema::ActionOutput.new( OFPP_FLOOD )
    #)

    macsa   = message.macsa
    macda   = message.macda
    in_port = message.in_port

    # MACテーブルの更新/追加
    if @mactable[ macsa ]
      @mactable[ macsa ][ :port_number ] = in_port
    else
      @mactable[ macsa ] = { :mac => macsa, :port_number => in_port }
    end

    # 宛先MACアドレスの出力ポートをMACテーブルから取得し、パケット出力
    if @mactable[ macda ]
      # 出力ポートを指定して、パケット出力
      packet_out datapath_id, message, @mactable[ macda ][ :port_number ]
    else
      # 全ポートにフラッディング
      packet_out datapath_id, message, OFPP_FLOOD
    end
  end


  def packet_out datapath_id, message, out_port

    # debug 用
    if out_port == OFPP_FLOOD
      printf "in_port: %6d  out_port:  FLOOD  source_mac: %s  destination_mac: %s\n", message.in_port, message.macsa, message.macda
    else
      printf "in_port: %6d  out_port: %6d  source_mac: %s  destination_mac: %s\n", message.in_port, out_port, message.macsa, message.macda
    end

    # 出力
    send_packet_out(
      datapath_id,
      :packet_in => message,
      :actions => Trema::ActionOutput.new( out_port )
    )
  end

end
