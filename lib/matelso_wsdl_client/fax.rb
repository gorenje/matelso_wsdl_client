module MatelsoWsdlClient

  class Client

    # Send a a PDF document as fax to a particular destination. Propagate any exceptions
    # to the callee.
    #
    # Required parameters:
    #
    #    - destination: complete number to whom the fax should be sent.
    #                         this should with internatinal predial, 49123123456789
    #    - pdf_data: Binary pdf data to be sent as fax.
    #
    # Optional Parameters that are taken from configuration if not set:
    #
    #    - billid - a reference that appears on the invoice. 
    #    - referenceid - 
    #    - sessionid -
    #    - station_info - Name of the sender
    #    - station_number - Number of the fax machine sending this fax.
    #    - retry_count - how many times should be retried before giving up.
    #    - email - Email address to send status upon failure or success.
    #
    # Further reading (german) (direct link not working):
    #   https://www.matelso.de/web/Downloads/tabid/137/Default.aspx 
    def fax!(opts)
      check_for_parameters([:destination, :pdf_data], opts)
      
      client, defaults = Savon::Client.new(@fax_wsdl_url), (@defaults["fax"] || {})

      resp = handle_response_errors do
        client.send_fax do |soap| 
          soap.body = { 
            "wsdl:PartnerId"         => @partner_id,
            "wsdl:PartnerPassword"   => @partner_password,
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
  end
end
