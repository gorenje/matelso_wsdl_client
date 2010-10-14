require 'rubygems'
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'matelso_wsdl_client'

class Test::Unit::TestCase
  should "do something" do
    client = MatelsoWsdlClient::Client.new("fubar", "snagu", 0)
    client.send_fax(:fax_data)
  end
end
