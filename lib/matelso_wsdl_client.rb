require 'savon'

module MatelsoWsdlClient
  
  Click2FaxWsdl = "http://www.matelso.de/Partnerbereich/Matelso_Click2Faxservice_v_1_0.asmx?WSDL"

  class Client
    attr_accessor :partner_id, :partner_password, :partner_account
    
    def initialize(pid, ppword, paccount, opts = {})
      @partner_id = pid
      @partner_password = ppword
      @partner_account = paccount
      
      @fax_wsdle_url = opts[:fax_wsdl_url] || Click2FaxWsdl
    end
  end
end

%w(
 click_to_fax
).each { |a| require "matel_wsdl_client/#{a}.rb"}
