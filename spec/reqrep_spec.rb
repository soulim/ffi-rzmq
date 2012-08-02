
require File.join(File.dirname(__FILE__), %w[spec_helper])

module ZMQ


  describe Socket do

    context "when running ping pong" do
      include APIHelper

      let(:string) { "booga-booga" }

      before(:all) do
        @context = ZMQ::Context.new 1
      end
      
      after(:all) do
        @context.terminate
      end

      # reset sockets each time because we only send 1 message which leaves
      # the REQ socket in a bad state. It cannot send again unless we were to
      # send a reply with the REP and read it.
      before(:each) do
        @ping = @context.socket ZMQ::REQ
        @pong = @context.socket ZMQ::REP
        port = bind_to_random_tcp_port(@pong)
        @ping.connect "tcp://127.0.0.1:#{port}"
        connect_sleep
      end

      after(:each) do
        @ping.close
        @pong.close
      end
      
      def send_ping(string)
        @ping.send_string string
        received_message = ''
        rc = @pong.recv_string received_message
        [rc, received_message]
      end

      it "should receive an exact string copy of the string message sent" do
        rc, received_message = send_ping(string)
        received_message.should == string
      end
      
      it "should generate a EFSM error when sending via the REQ socket twice in a row without an intervening receive operation" do
        send_ping(string)
        rc = @ping.send_string(string)
        rc.should == -1
        Util.errno.should == ZMQ::EFSM
      end

      it "should receive an exact copy of the sent message using Message objects directly" do
        received_message = Message.new

        rc = @ping.sendmsg(Message.new(string))
        LibZMQ.version2? ? rc.should == 0 : rc.should == string.size
        rc = @pong.recvmsg received_message
        LibZMQ.version2? ? rc.should == 0 : rc.should == string.size

        received_message.copy_out_string.should == string
      end

      it "should receive an exact copy of the sent message using Message objects directly in non-blocking mode" do
        sent_message = Message.new string
        received_message = Message.new

        rc = @ping.sendmsg(Message.new(string), ZMQ::NonBlocking)
        LibZMQ.version2? ? rc.should == 0 : rc.should == string.size
        delivery_sleep
        rc = @pong.recvmsg received_message, ZMQ::NonBlocking
        LibZMQ.version2? ? rc.should == 0 : rc.should == string.size

        received_message.copy_out_string.should == string
      end

    end # context ping-pong


  end # describe


end # module ZMQ
