require 'helper'
require 'tempfile'
require 'yaml'

# Warning:
#   The test contact the actual service of Matelso, there is no mocking going on here ...
#   But they've not complained yet!
class TestMatelsoWsdlClient < Test::Unit::TestCase
  def with_tempfile(&block)
    Tempfile.open("matelso-test") do |tempfile|
      yield(tempfile)
    end
  end
  
  context "configuration" do
    should "accept a string" do
      client = nil
      with_tempfile do |tempfile|
        tempfile << ({"partner" => {"id" => 1, "password" => 2, "account" => 4} }.to_yaml)
        tempfile.flush
        client = MatelsoWsdlClient::Client.new(tempfile.path)
      end
      assert_equal 1, client.partner_id
      assert_equal 2, client.partner_password
      assert_equal 4, client.partner_account
    end

    should "accept a file" do
      client = nil
      with_tempfile do |tempfile|
        tempfile << ({"partner" => {"id" => 1, "password" => 2, "account" => 4} }.to_yaml)
        tempfile.flush
        client = MatelsoWsdlClient::Client.new(File.open(tempfile.path))
      end
      assert_equal 1, client.partner_id
      assert_equal 2, client.partner_password
      assert_equal 4, client.partner_account
    end
    
    should "accept a hash" do
      client = MatelsoWsdlClient::Client.
        new({"partner" => {"id" => 1, "password" => 2, "account" => 4} })
      assert_equal 1, client.partner_id
      assert_equal 2, client.partner_password
      assert_equal 4, client.partner_account
    end
  end
  
  context "fax" do
    should "fail if destination or data were not provided" do
      client = MatelsoWsdlClient::Client.new({ "partner"=>{"id"=>12, "password"=>12, "account"=>3 }})
      [:fax, :fax!].each do |method_name|
        assert_raises MatelsoWsdlClient::NotEnoughParameters, "Failed for #{method_name}" do
          client.send(method_name, :pdf_data => "a")
        end
        assert_raises MatelsoWsdlClient::NotEnoughParameters, "Failed for #{method_name}" do
          client.send(method_name, :destination => "a")
        end
      end
    end
    
    should "fail if nothing is set that makes sense" do
      client = MatelsoWsdlClient::Client.new({ "partner"=>{"id"=>12, "password"=>12, "account"=>3 }})
      assert !client.fax(:pdf_data => "a", :destination => "1234")
    end

    should "Soap fault" do
      client = MatelsoWsdlClient::Client.new({ "partner"=>{"id"=>12, "password"=>12, "account"=>3 }})
      assert_raises Savon::SOAPFault do
        client.fax!(:pdf_data => "a", :destination => "1234")
      end
    end
  end
  
  context "call" do
    should "fail if not all required parameters are provided" do
      client = MatelsoWsdlClient::Client.new({ "partner"=>{"id"=>12, "password"=>12, "account"=>3 }})

      [:call, :call!].each do |method_name|
        assert_raises MatelsoWsdlClient::NotEnoughParameters, "Failed for #{method_name}" do
          client.send(method_name, :to_area_code => "1", :to_number => "2")
        end
        assert_raises MatelsoWsdlClient::NotEnoughParameters, "Failed for #{method_name}" do
          client.send(method_name, :to_area_code => "1", :to_number => "2",
                      :from_area_code => "1", :from_number => "2")
        end
        assert_raises MatelsoWsdlClient::NotEnoughParameters, "Failed for #{method_name}" do
          client.send(method_name, :to_area_code => "1", :to_number => "2",
                      :error_area_code => "1", :error_number => "2")
        end
        assert_raises MatelsoWsdlClient::NotEnoughParameters, "Failed for #{method_name}" do
          client.send(method_name, :error_area_code => "1", :error_number => "2",
                      :from_area_code => "1", :from_number => "2")
        end
      end
    end
    
    should "fail with an soap fault" do
      client = MatelsoWsdlClient::Client.new({ "partner"=>{"id"=>12, "password"=>12, "account"=>3 }})
      assert_raises Savon::SOAPFault do
        client.call!(:error_area_code => "1", :error_number => "2",
                     :from_area_code => "1", :from_number => "2",
                     :to_area_code => "12", :to_number => '213')
      end
    end
  end

  context "vanity" do
    should "fail if not all required parameters are provided" do
      client = MatelsoWsdlClient::Client.new({"partner"=>{"id"=>12, "password"=>12, "account"=>3}})
      [:vanity, :vanity!].each do |method_name|
        assert_raises MatelsoWsdlClient::NotEnoughParameters, "Failed for #{method_name}" do
          client.send(method_name, :country_code => "1", :number => "2")
        end
        assert_raises MatelsoWsdlClient::NotEnoughParameters, "Failed for #{method_name}" do
          client.send(method_name, :country_code => "1")
        end
        assert_raises MatelsoWsdlClient::NotEnoughParameters, "Failed for #{method_name}" do
          client.send(method_name, :country_code => "1", :password => 1)
        end
        assert_raises MatelsoWsdlClient::NotEnoughParameters, "Failed for #{method_name}" do
          client.send(method_name, :country_code => "1", :password => 1, :area_code => 12)
        end
      end
    end

    should "fail with an soap fault" do
      client = MatelsoWsdlClient::Client.new({ "partner"=>{"id"=>12, "password"=>12, "account"=>3 }})
      assert_raises Savon::SOAPFault do
        client.vanity!(:country_code => "1", :password => 1, :area_code => 12, :number => 12)
      end
    end
  end
end
