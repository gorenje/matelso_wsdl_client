module MatelsoWsdlClient

  class Client

    # Connect two numbers so that they can call each other.
    #
    # Required parameters:
    #
    #   - from_area_code & from_number ==> the caller (gets called first)
    #   - to_area_code & to_number ==> the callee
    #   - error_prefix & error_number ==> number to call if the call could not be made.
    #
    # Each area code has to be provided, since there is no easy to determine this. 
    # An area code should be prefix with '0', so it needs to be a string, e.g. '030'
    # if you happen to be living in Berlin, Germany.
    #
    # Optional parameters, taken from configuration if not set:
    #
    #   - announcemnt_from - the audio file to play for the caller
    #   - announcemnt_to - the audio file to play for the callee
    #
    # Both these audio files need to have been uploaded to the Matelso servers in
    # order to be played. I.e. these are file names, not binary data.
    #
    #   - max_call_duration - in seconds, after this many seconds, the call is immediately
    #                         stopped
    #   - max_ring_count - maximal number of rings before the call is stopped. This
    #                      references to the number of times the phone rings at the
    #                      to_number, i.e. at the callees' end.
    #   - call_delay - in seconds, the delay before the call is attempted. This is the
    #                  delay in calling the from_number, i.e. the caller, not the callee.
    #                  Once the caller has answered the phone, the callee is immediately
    #                  called.
    #
    # Further reading (german):
    #  https://www.matelso.de/web/LinkClick.aspx?fileticket=f%2bmo5Lf%2bN4w%3d&tabid=137
    def call!(opts)
      check_for_parameters([:from_area_code, :from_number,
                            :to_area_code, :to_number,
                            :error_area_code, :error_number], opts)

      client, defaults = Savon::Client.new(@call_wsdl_url), (@defaults["call"] || {})

      resp = handle_response_errors do
        client.call_call_initiieren do |soap|
          soap.body = { 
            'wsdl:Ortsnetz1'       => getp(:from_area_code, opts),
            'wsdl:Nummer1'         => getp(:from_number, opts),
            'wsdl:Ortsnetz2'       => getp(:to_area_code, opts),
            'wsdl:Nummer2'         => getp(:to_number, opts),
            'wsdl:Ansage1'         => def_or_paras(:announcement_from,defaults,opts),       
            "wsdl:Ansage2"         => def_or_paras(:announcement_to,defaults,opts),
            'wsdl:MaxDauer'        => def_or_paras(:max_call_duration,defaults,opts),
            'wsdl:Delay1'          => def_or_paras(:call_delay,defaults,opts),
            'wsdl:MaxRing2'        => def_or_paras(:max_ring_count,defaults,opts),
            'wsdl:Ortsnetz3'       => getp(:error_area_code, opts),
            'wsdl:Nummer3'         => getp(:error_number, opts),
            'wsdl:PartnerId'       => @partner_id,  
            'wsdl:Partnerkennwort' => @partner_password,
          }
        end
      end

      ## TODO do something with the resp ...
    end
  end
end
