# To run these specs using rake, make sure the 'bones' and 'bones-extras'
# gems are installed. Then execute 'rake spec' from the main directory
# to run all specs.

require File.expand_path(
File.join(File.dirname(__FILE__), %w[.. lib ffi-rzmq]))

require 'thread' # necessary when testing in MRI 1.8 mode
Thread.abort_on_exception = true

# define some version guards so we can turn on/off specs based upon
# the version of the 0mq library that is loaded
def version2?
  ZMQ::LibZMQ.version2?
end

def version3?
  ZMQ::LibZMQ.version3?
end


SLEEP_SHORT = 0.1
SLEEP_LONG = 0.3

def delivery_sleep() sleep(SLEEP_SHORT); end
def connect_sleep() sleep(SLEEP_SHORT); end
def bind_sleep() sleep(SLEEP_LONG); end
def thread_startup_sleep() sleep(1.0); end

module APIHelper
  def stub_libzmq
    @err_str_mock = mock("error string")

    LibZMQ.stub!(
    :zmq_init => 0,
    :zmq_errno => 0,
    :zmq_sterror => @err_str_mock
    )
  end

  # generate a random port between 10_000 and 65534
  def random_port
    rand(55534) + 10_000
  end

  def bind_to_random_tcp_port(socket, max_tries = 500)
    tries = 0
    rc = -1

    while !ZMQ::Util.resultcode_ok?(rc) && tries < max_tries
      tries += 1
      random = random_port
      rc = socket.bind(local_transport_string(random))
    end
    
    unless ZMQ::Util.resultcode_ok?(rc)
      raise "Could not bind to random port successfully; retries all failed!"
    end

    random
  end

  def connect_to_random_tcp_port socket, max_tries = 500
    tries = 0
    rc = -1

    while !ZMQ::Util.resultcode_ok?(rc) && tries < max_tries
      tries += 1
      random = random_port
      rc = socket.connect(local_transport_string(random))
    end
    
    unless ZMQ::Util.resultcode_ok?(rc)
      raise "Could not connect to random port successfully; retries all failed!"
    end

    random
  end
  
  def local_transport_string(port)
    "tcp://127.0.0.1:#{port}"
  end

  def assert_ok(rc)
    raise "Failed with rc [#{rc}] and errno [#{ZMQ::Util.errno}], msg [#{ZMQ::Util.error_string}]! #{caller(0)}" unless rc >= 0
  end
end
