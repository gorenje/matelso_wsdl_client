# -*- coding: utf-8 -*-
module MatelsoWsdlClient
  class Client

    # Create a vanity number that can be used to route a caller over Matelso
    # to the destination number. This allows for call tracking via Matelso.
    # Matelso can provide access to the statistics via an FTP account.
    # 
    # The number generated has a litetime (days) but can be cancelled at any
    # time.
    # 
    # Required parameters:
    #   - country_code - of the number to route to, e.g. "49"
    #   - area_code - of the number to route, e.g. "030"
    #   - number - the number without area_code and country code, e.g. "182720"
    #   - password - set this to obtain information about the vanity number generated.
    # 
    # Optional parameters, taken from the cofiguration if not set:
    #   - email - "email for future services" -- what ever that means.
    #   - expire_after - number of days after the vanity numbers is deleted.
    #
    # Note that this service requires extra contract with Matelso.
    #
    # On failure, various exceptions are thrown:
    #   - MatelsoHttpError < RuntimeError ; end
    #   - MatelsoSoapError < RuntimeError ; end
    #   - MatelsoFailedMe < RuntimeError ; end
    #
    # On Success this returns an array containing:
    #   - 0 -> the vanity number
    #   - 1 -> valid until as date
    #
    # Further reading (german):
    #   https://www.matelso.de/web/Portals/0/MaTelSo%20Dienstbeschreibung%20Matketing%20Rufnummern%20Service%20V2_2.pdf
    def vanity!(opts)
      check_for_parameters([:country_code, :area_code, :number,:password], opts)
      client, defaults = Savon::Client.new(@vanity_wsdl_url), (@defaults["vanity"] || {})

      resp = handle_response_errors do
        client.rufnummer_erzeugen do |soap|
          soap.body = { 
            "wsdl:PartnerId"          => @partner_id,
            "wsdl:Partnerkennwort"    => @partner_password,
            "wsdl:Laendercode"        => getp(:country_code, opts),
            "wsdl:Ortsnetz"           => getp(:area_code, opts),
            "wsdl:Anschlussnummer"    => getp(:number, opts),
            "wsdl:E_Mail"             => def_or_paras(:email, defaults, opts),
            "wsdl:Rufnummernkennwort" => getp(:password, opts),
            "wsdl:Dauer"              => def_or_paras(:expire_after, defaults, opts),
          }
        end
      end

      # transactional errors
      hsh = resp.to_hash[:rufnummer_erzeugenresponse][:rufnummer_erzeugenresult][:diffgram][:newdataset][:"myadmin.rufnummernstatus"]

      if hsh[:transaktionsergebnis]
        [hsh[:chiffre_rufnummer], hsh[:"gültig_bis"]]
      else
        raise MatelsoFailedMe, "Reason: #{hsh[:abfrageergebnis]}"
      end
    end
  end
end
