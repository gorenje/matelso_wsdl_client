module MatelsoWsdlClient

  class Client

    def send_fax(opts)

      raise "No destination or fax data provided" if (opts[:destination].nil? or
                                                      opts[:fax_data])
      client = Savon::Client.new @fax_wsdl_url

      response = client.send_fax do |soap| 
        soap.body = { 
          "wsdl:PartnerId"         => @partner_id,
          "wsdl:PartnerPassword"   => @partner_password,
          "wsdl:Account"           => @partner_account,
          "wsdl:BillId"            => "TEST", ## TODO set to some sensible
          "wsdl:RefId"             => "42",  ## TODO set to some sensible
          "wsdl:SessionId_Partner" => "1340",  ## TODO set to some sensible
          "wsdl:Destination"       => opts[:destination],
          "wsdl:PDFFile"           => Base64.encode64(opts[:fax_data]),
          "wsdl:FaxStationInfo"    => fax_station_info,
          "wsdl:FaxStationNumber"  => fax_station_number,
          "wsdl:retrycount"        => fax_retry_count,
          "wsdl:EMailAdress"       => fax_email,
        }
      end
      response.to_hash["send_fax_result"]
    end
  end
end
