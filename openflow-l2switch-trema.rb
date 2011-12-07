class L2Switch < Trema::Controller

  def start
    @fdb = FDB.new
  end

  def packet_in datapath_id, message

    #send_flow_mod_add(
    #  datapath_id,
    #  :idle_timeout => 10,
    #  :hart_timeout => 10,
    #  :match => ExactMatch.from( message ),
    #  :actions => Trema::ActionOutput.new( OFPP_FLOOD )
    #)

    @fdb.learn message.macsa, message.in_port
    out_port = @fdb.lookup (message.macda)

    if out_port
      packet_out datapath_id, message, out_port
    else
      packet_out datapath_id, message, OFPP_FLOOD
    end
  end

  def packet_out datapath_id, message, out_port
    puts "in_port: #{message.in_port} out_port: #{out_port} source_mac: #{message.macsa}  destination_mac: #{message.macda}"
    send_packet_out(
      datapath_id,
      :packet_in => message,
      :actions => Trema::ActionOutput.new( out_port )
    )
  end

end

class FDB
  def initialize
    @db = {}
  end


  def lookup mac
    if @db[ mac ]
      @db[ mac ][ :port_number ]
    else
      nil
    end
  end


  def learn mac, port_number
    if @db[ mac ]
      @db[ mac ][ :port_number ] = port_number
    else
      @db[ mac ] = { :mac => mac, :port_number => port_number }
    end
  end
end
