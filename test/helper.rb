require 'rubygems'
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'matelso_wsdl_client'

class Test::Unit::TestCase
  def assert_authentication_error(&block)
    result = yield
    assert_equal "error", result[:status]
    assert_equal "Authentication failed", result[:msg]
    result
  end

  def with_tempfile(&block)
    Tempfile.open("matelso-test") do |tempfile|
      yield(tempfile)
    end
  end
  
  # if you want to do a "live" test, then define the correct authentication 
  # details on the command line, e.g.
  #      pid=partner-id ppword='partnerpword' paccount=partner-account \
  #         ruby test/test_matelso_wsdl_client.rb -n "/work if parameters defined/"
  def get_client(klazz = MatelsoWsdlClient::Client)
    klazz.new({"partner" => {
                  "id"       => ENV["pid"]      || 12, 
                  "password" => ENV["ppword"]   || 12, 
                  "account"  => ENV["paccount"] || 3
                }})
  end
end
