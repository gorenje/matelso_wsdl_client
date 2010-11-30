module MatelsoWsdlClient::MRS

  # MRS or Marketing Rufnummer Service is basically the new version of the vanity
  # interface. But instead of throwing out the old interface, this is an implementation
  # of the new interface.
  #
  # Note: that vanity number is, in fact, completely incorrect terminology. The numbers
  # generated here are random and have as much to do with vanity as Ugly Uncle Joes Ugly Ass. But
  # it's, IMHO, still much preferable to b_number (resp. b_nummer) and c_number (resp. c_nummer).
  #
  # A typical vanity number creation goes like this:
  #   1. create_subscriber! 
  #      Creates a new subscriber with Matelso. Because they check the address 
  #      information, this always returns ok. Once they have done their checking, 
  #      the call an URL on our side to notify us that everything went well.
  #   1a. Asynch call to an URL one has defined with Matelso. This provides a status
  #       and if the subscriber was successful created, a subscriber_id
  #   2. create_vanity_number!
  #      This creates a new vanity number for a subscriber -- only works if step 1a was ok.
  #      Area_code parameter is without leading zero, i.e. 0234 becomes 234.
  #   3. route_vanity_number!
  #      Is used to map a vanity number to a destination number, i.e. the one that should
  #      be called if vanity number is used. Both numbers have to be in E.164 format.
  #
  # To remove a subscriber, you'll have to remove all the corresponding vanity numbers for
  # the subscriber (delete_vanity_number!) and then the subscriber (delete_subscriber!).
  # Note though, you'll have to track the vanity_number association to subscriber yourself
  # (Warning: a subscriber can have multiple vanity numbers) because there is no way of 
  # obtaining this information from the Matelso API (not at time of writing). Show_subscriber!
  # does not list the vanity numbers of the respective subscriber.
  
  class Client < MatelsoWsdlClient::Client
    
    # house_number_additive is actually optional, but a value of "" is as good as 
    # being optional.
    def create_subscriber!(opts)
      all_parameters = ["salutation", "first_name", "last_name", "firm_name",
                        "legal_form", "street", "house_number", 
                        "house_number_additive", "postcode", "city", "country"]

      check_for_parameters(all_parameters, opts)
      
      resp = with_client_and_defaults do |client, defaults|
        handle_response_errors do
          client.create_subscriber do |soap| 
            soap.body = add_soap_prefix do
              all_parameters.inject({}) { |t, key| t.merge(key => getp(key,opts)) }.
                merge({ "partner_id"         => @partner_id,
                        "partner_password"   => @partner_password,
                      })
            end
          end
        end
      end
      
      handle_response_hash(get_response_hash(resp, [:create_subscriber_response, 
                                                    :create_subscriber_result])) do |hsh|
        { :subscriber_id => hsh[:data][:subscriber_id] }
      end
    end
    
    # remove a subscriber after creation.
    # Parameters:
    #   subscriber_id: as returned by create_subscriber!
    def delete_subscriber!(opts)
      check_for_parameters([:subscriber_id], opts)
      
      resp = with_client_and_defaults do |client, defaults|
        handle_response_errors do
          client.delete_subscriber do |soap| 
            soap.body = add_soap_prefix do 
              { 
                "partner_id"       => @partner_id,
                "partner_password" => @partner_password,
                "subscriber_id"    => getp(:subscriber_id,opts),
              }
            end
          end
        end
      end
      
      handle_response_hash(get_response_hash(resp, [:delete_subscriber_response, 
                                                    :delete_subscriber_result])) do |hsh|
        { :deleted_subscriber_id => getp(:subscriber_id,opts) }
      end
    end
    
    # Return a list of all active Subscribers.
    def show_subscribers!
      resp = with_client_and_defaults do |client, defaults|
        handle_response_errors do
          client.show_subscriber do |soap| 
            soap.body = add_soap_prefix do 
              { 
                "partner_id"       => @partner_id,
                "partner_password" => @partner_password,
              }
            end
          end
        end
      end
      
      handle_response_hash(get_response_hash(resp, [:show_subscriber_response, 
                                                    :show_subscriber_result])) do |hsh|
        { :subscribers => hsh[:data] }
      end
    end
    
    # Matelso has a description for a show_subscriber method but unfornuately that
    # should be called show_subscriberS, i.e. it returns all subscribers. So this
    # wrapper provides the functionality as long as Matelso does not provide it.
    def show_subscriber!(opts)
      check_for_parameters([:subscriber_id], opts)

      subscriber = (show_subscribers![:subscribers] || []).
        select { |subser| subser[:subscriber_id] == getp(:subscriber_id,opts).to_s }.
        first

      if subscriber
        { :status => "ok", :subscriber => subscriber }
      else
        { :status => "error", 
          :msg => "No subscriber found with ID '#{getp(:subscriber_id,opts)}'" 
        }
      end
    end
    
    # This generates the "b_number" that can be used to route to the actual number
    # of the customer.
    #
    # Parameters (obtained via Asynch callback from Matelso):
    #   subscriber_id: subscriber id obtained via callback from matelso.
    #   area_code: is the ndc returned by the asynch call from Matelso callback.
    def create_vanity_number!(opts)
      check_for_parameters([:area_code, :subscriber_id], opts)

      resp = with_client_and_defaults do |client, defaults|
        handle_response_errors do
          client.assign_b_number do |soap| 
            soap.body = add_soap_prefix do 
              { 
                "partner_id"       => @partner_id,
                "partner_password" => @partner_password,
                "subscriber_id"    => getp(:subscriber_id, opts),
                "subscriber_ndc"   => getp(:area_code, opts)
              }
            end
          end
        end
      end
      
      handle_response_hash(get_response_hash(resp, [:assign_b_number_response, 
                                                    :assign_b_number_result])) do |hsh|
        d = hsh[:data]
        # Not being a Telco person myself:
        #   NDC - National Destination Code
        #   SN - Subscriber Number
        { :country_code => d[:cc], :area_code => d[:ndc], :vanity_number => d[:sn] }
      end
    end
    
    def delete_vanity_number!(opts)
      check_for_parameters([:vanity_number], opts)

      resp = with_client_and_defaults do |client, defaults|
        handle_response_errors do
          client.delete_b_number do |soap| 
            soap.body = add_soap_prefix do
              { 
                "partner_id"        => @partner_id,
                "partner_password"  => @partner_password,
                "b_number"          => getp(:vanity_number, opts),
              }
            end
          end
        end
      end
      
      handle_response_hash( get_response_hash(resp, [:delete_b_number_response, 
                                                     :delete_b_number_result])) do |hsh|
        { :deleted_vanity_number => getp(:vanity_number, opts) }
      end
    end

    def route_vanity_number!(opts)
      check_for_parameters([:vanity_number, :dest_number], opts)

      resp = with_client_and_defaults do |client, defaults|
        handle_response_errors do
          client.apply_profile do |soap| 
            soap.body = add_soap_prefix do
              { 
                "partner_id"       => @partner_id,
                "partner_password" => @partner_password,
                "b_number"         => getp(:vanity_number, opts),
                "c_number"         => getp(:dest_number, opts),
              }
            end
          end
        end
      end

      handle_response_hash( get_response_hash(resp, [:apply_profile_response, 
                                                     :apply_profile_result]) ) do |hsh|
        { :vanity_number => getp(:vanity_number, opts), :dest_number => getp(:dest_number, opts) }
      end
    end
    
    
    # used to test the callback URL defined with Matelso.
    def test_callback_url!
      resp = with_client_and_defaults do |client, defaults|
        handle_response_errors do
          client.get_testrequest do |soap| 
            soap.body = add_soap_prefix do 
              { 
                "partner_id"       => @partner_id,
                "partner_password" => @partner_password,
              }
            end
          end
        end
      end
      
      handle_response_hash( get_response_hash(resp, [:get_testrequest_response, 
                                                     :get_testrequest_result]) ) do |hsh|
        {}
      end
    end

    ## 
    ## Helpers from here on end.
    ##
    private
    
    # Shortcut so that we don't have to write the same line of code every time.
    def with_client_and_defaults(&block)
      client, defaults = Savon::Client.new(@mrs_wsdl_url), (@defaults["mrs"] || {})
      yield(client, defaults)
    end
    
    # Retrieve the item element from around it's casing. If it's not available,
    # then we return an empty hash.
    def get_response_hash(response, casing)
      (casing + [:item]).inject(response.to_hash) { |rhsh, elem| rhsh[elem] || {} }
    end
    
    # pass in the result hash from the soap call and define (in the block) the code that
    # should be executed on success. This returns a hash that is merged with the hash
    # that is returned on success.
    def handle_response_hash(hsh, &block)
      case hsh[:status]
      when "failed" 
        { :status => "error", 
          :msg => ("%s %s" % [:message,:additional_message].map {|a| hsh[:data][a]}).strip
        }
      when "success"
        { :status => "ok" }.merge(yield(hsh))
      else
        { :status => "unknown",
          :data => hsh
        }
      end
    end

    # Add 'wsdl:' to all key names. This is required for Savon but doesn't really interest
    # us (me certainly not). This should be used with the other methods (e.g. fax) too.
    def add_soap_prefix(hsh=nil, &block)
      (hsh || yield).inject({}) { |t,(key, value)| t.merge( "wsdl:#{key}" => value ) }
    end
  end
end

