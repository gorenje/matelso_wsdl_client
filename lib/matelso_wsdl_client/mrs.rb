module MatelsoWsdlClient

  class Client
    # MRS or Marketing Rufnummer Service is basically the new version of the vanity
    # interface. But instead of throwing out the old interface, this is an implementation
    # of the new interface. Strangely also version 2.0.
    
    def create_subscriber!(opts)
      check_for_parameters([:destination, :pdf_data], opts)
      
      client, defaults = Savon::Client.new(@mrs_wsdl_url), (@defaults["mrs"] || {})

      resp = handle_response_errors do
        client.create_subscriber do |soap| 
          soap.body = { 
            "wsdl:partner_id"         => @partner_id,
            "wsdl:partner_password"   => @partner_password,

            
            "wsdl:Account"           => @partner_account,
            "wsdl:BillId"            => def_or_paras(:billid, defaults, opts),
            "wsdl:RefId"             => def_or_paras(:referenceid, defaults, opts),
            "wsdl:SessionId_Partner" => def_or_paras(:sessionid, defaults, opts),
            "wsdl:Destination"       => getp(:destination, opts),
            "wsdl:PDFFile"           => Base64.encode64(getp(:pdf_data,opts)),
            "wsdl:FaxStationInfo"    => def_or_paras(:station_info, defaults, opts),
            "wsdl:FaxStationNumber"  => def_or_paras(:station_number, defaults, opts),
            "wsdl:retrycount"        => def_or_paras(:retry_count, defaults, opts),
            "wsdl:EMailAdress"       => def_or_paras(:email, defaults, opts),
          }
        end
      end

      ## TODO do more with the response
      resp.to_hash["send_fax_result"]
    end

    
    def create_vanity_number!(opts)
      check_for_parameters([:area_code, :subscriber_id], opts)

      client, defaults = Savon::Client.new(@mrs_wsdl_url), (@defaults["mrs"] || {})

      resp = handle_response_errors do
        client.assign_b_number do |soap| 
          soap.body = { 
            "wsdl:partner_id"         => @partner_id,
            "wsdl:partner_password"   => @partner_password,
            "wsdl:subscriber_id"     => getp(:subscriber_id, opts),
            "wsdl:subscriber_ndc"    => getp(:area_code, opts)
          }
        end
      end
      
      ## TODO do more with this response
      resp
    end
    
    def route_vanity_number!(opts)
      check_for_parameters([:vanity_number, :dest_number], opts)

      client, defaults = Savon::Client.new(@mrs_wsdl_url), (@defaults["mrs"] || {})
      resp = handle_response_errors do
        client.apply_profile do |soap| 
          soap.body = { 
            "wsdl:partner_id"         => @partner_id,
            "wsdl:partner_password"   => @partner_password,
            "wsdl:b_number"           => getp(:vanity_number, opts),
            "wsdl:c_number"           => getp(:dest_number, opts),
          }
        end
      end
      ## TODO do more with the response
      resp
    end

    def delete_vanity_number!(opts)
      check_for_parameters([:vanity_number], opts)

      client, defaults = Savon::Client.new(@mrs_wsdl_url), (@defaults["mrs"] || {})

      resp = handle_response_errors do
        client.delete_b_number do |soap| 
          soap.body = { 
            "wsdl:partner_id"         => @partner_id,
            "wsdl:partner_password"   => @partner_password,
            "wsdl:b_number"           => getp(:vanity_number, opts),
          }
        end
      end

      ## TODO do more with this response
      resp
    end
  end
end
