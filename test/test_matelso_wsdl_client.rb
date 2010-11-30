# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/helper.rb'
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
  
  # if you want to do a "live" test, then define the correct authentication details on the command
  # line, e.g.
  #      pid=partner-id ppword='partnerpword' paccount=partner-account \
  #         ruby test/test_matelso_wsdl_client.rb -n "/work if parameters defined/"
  def get_client(klazz = MatelsoWsdlClient::Client)
    klazz.new({"partner" => {
                  "id"       => ENV["pid"]      || 12, 
                  "password" => ENV["ppword"]   || 12, 
                  "account"  => ENV["paccount"] || 3
                }})
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
      client = get_client
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
      client = get_client
      assert !client.fax(:pdf_data => "a", :destination => "1234")
    end

    should "Soap fault" do
      client = get_client
      assert_raises Savon::SOAPFault do
        client.fax!(:pdf_data => "a", :destination => "1234")
      end
    end
  end
  
  context "call" do
    should "fail if not all required parameters are provided" do
      client = get_client

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
      client = get_client
      assert_raises Savon::SOAPFault do
        client.call!(:error_area_code => "1", :error_number => "2",
                     :from_area_code => "1", :from_number => "2",
                     :to_area_code => "12", :to_number => '213')
      end
    end
  end

  context "vanity" do
    should "fail if not all required parameters are provided" do
      client = get_client
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
      client = get_client
      assert_raises Savon::SOAPFault do
        client.vanity!(:country_code => "1", :password => 1, :area_code => 12, :number => 12)
      end
    end
  end

  context "mrs" do
    should "create_subscriber requires a bunch of parameters" do
      client = get_client(MatelsoWsdlClient::MRS::Client)
      assert_raises MatelsoWsdlClient::NotEnoughParameters do
        client.create_subscriber!({})
      end
    end
    
    should "create_subscriber work if parameters defined" do
      parameters = {
        :salutation            => "Herr", 
        :first_name            => "Ingo", 
        :last_name             => "Bohg", 
        :firm_name             => "TopTarif",
        :legal_form            => "GmbH", 
        :street                => "Schönhauser Allee", 
        :house_number          => 6, 
        :house_number_additive => "", 
        :postcode              => "10119", 
        :city                  => "Berlin", 
        :country               => "DE"
      }

      client = get_client(MatelsoWsdlClient::MRS::Client)
      result = client.create_subscriber!(parameters)
      assert_equal "error", result[:status]
      assert_equal "Authentication failed", result[:msg]
    end
    
    should "be able to delete one subscriber" do
      parameters = {
        :subscriber_id => ENV["subid"] || 12345
      }
      
      client = get_client(MatelsoWsdlClient::MRS::Client)
      result = client.delete_subscriber!(parameters)
      assert_equal "error", result[:status]
      assert_equal "Authentication failed", result[:msg]
    end
    
    should "be able to show all subscribers" do
      client = get_client(MatelsoWsdlClient::MRS::Client)
      result = client.show_subscribers!

      ## can be used to display information on the subscribers
      # tmp = [:subscriber_id, :ndc, :first_name, :last_name, :firm_name]
      # result[:subscribers].each do |sub|
      #  puts "ID: %s NDC: %s Name: %s %s Company: %s" % tmp.map { |a| sub[a] }
      # end
      
      assert_equal "error", result[:status]
      assert_equal "Authentication failed", result[:msg]
    end

    should "be able to show one subscriber" do
      parameters = {
        :subscriber_id => ENV["subid"] || 12345
      }
      
      client = get_client(MatelsoWsdlClient::MRS::Client)
      result = client.show_subscriber!(parameters)
      assert_equal "error", result[:status]
      assert_equal "No subscriber found with ID '#{parameters[:subscriber_id]}'", result[:msg]
    end
    
    should 'be able to get a vanity number' do
      parameters = { 
        :subscriber_id => ENV["subid"] || 12345,
        :area_code => ENV["area_code"] || "1234"
      }
      
      client = get_client(MatelsoWsdlClient::MRS::Client)
      result = client.create_vanity_number!(parameters)
      assert_equal "error", result[:status]
      assert_equal "Authentication failed", result[:msg]
    end
    
    should "be possible to delete a vanity number" do
      parameters = { 
        :vanity_number => ENV["vanity_number"] || 123456789,
      }
      
      client = get_client(MatelsoWsdlClient::MRS::Client)
      result = client.delete_vanity_number!(parameters)
      assert_equal "error", result[:status]
      assert_equal "Authentication failed", result[:msg]
    end
    
    should "be able to route vanity number" do
      parameters = { 
        :vanity_number => ENV["vanity_number"] || 123456789,
        :dest_number => ENV["dest_number"] || 123456789,
      }
      
      client = get_client(MatelsoWsdlClient::MRS::Client)
      result = client.route_vanity_number!(parameters)
      assert_equal "error", result[:status]
      assert_equal "Authentication failed", result[:msg]
    end
  end
end
