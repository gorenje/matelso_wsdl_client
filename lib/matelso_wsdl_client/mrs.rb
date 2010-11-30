module MatelsoWsdlClient::MRS

  # MRS or Marketing Rufnummer Service is basically the new version of the vanity
  # interface. But instead of throwing out the old interface, this is an implementation
  # of the new interface.
  #
  # A typical vanity number creation goes like this:
  #   1. create_subscriber! 
  #      Creates a new subscriber with Matelso. Because they check the address 
  #      information, this always returns ok. Once they have done their checking, 
  #      the call an URL on our side to notify us that everything went well.
  #   1a. Asynch call to an URL one has defined with Matelso. This provides a status
  #       and if the subscriber was successful created, a subscriber_id
  #   2. create_vanity_number!
  #      This creates a new vanity number of a subscriber -- only works if step 1a was ok.
  #      Area_code parameter is without leading zero.
  class Client < MatelsoWsdlClient::Client
    
    def create_subscriber!(opts)
      all_parameters = ["salutation", "first_name", "last_name", "firm_name",
                        "legal_form", "street", "house_number", 
                        "house_number_additive", "postcode", "city", "country"]

      check_for_parameters(all_parameters, opts)
      
      client, defaults = Savon::Client.new(@mrs_wsdl_url), (@defaults["mrs"] || {})
      
      resp = handle_response_errors do
        client.create_subscriber do |soap| 
          soap.body = add_soap_prefix do
            all_parameters.inject({}) { |t, key| t.merge(key => getp(key,opts)) }.
              merge({ "partner_id"         => @partner_id,
                      "partner_password"   => @partner_password,
                    })
          end
        end
      end

      ## Retrieve the item element if it's available, else hsh is empty. 
      hsh = [:create_subscriber_response, :create_subscriber_result, :item].
        inject(resp.to_hash) { |rhsh, elem| rhsh[elem] || {} }

      handle_response_hash(hsh) do |hsh|
        { :subscriber_id => hsh[:data][:subscriber_id] }
      end
    end
    
    # remove a subscriber after creation.
    # Parameters:
    #   subscriber_id: as returned by create_subscriber!
    def delete_subscriber!(opts)
      check_for_parameters([:subscriber_id], opts)
      
      client, defaults = Savon::Client.new(@mrs_wsdl_url), (@defaults["mrs"] || {})

      resp = handle_response_errors do
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
      
      ## Retrieve the item element if it's available, else hsh is empty. 
      hsh = [:delete_subscriber_response, :delete_subscriber_result, :item].
        inject(resp.to_hash) { |rhsh, elem| rhsh[elem] || {} }

      handle_response_hash(hsh) do |hsh|
        { :deleted_subscriber_id => getp(:subscriber_id,opts) }
      end
    end
    
    
    # Return a list of all active Subscribers.
    def show_subscribers!
      client, defaults = Savon::Client.new(@mrs_wsdl_url), (@defaults["mrs"] || {})

      resp = handle_response_errors do
        client.show_subscriber do |soap| 
          soap.body = add_soap_prefix do 
            { 
              "partner_id"       => @partner_id,
              "partner_password" => @partner_password,
            }
          end
        end
      end

      ## Retrieve the item element if it's available, else hsh is empty. 
      hsh = [:show_subscriber_response, :show_subscriber_result, :item].
        inject(resp.to_hash) { |rhsh, elem| rhsh[elem] || {} }
      
      handle_response_hash(hsh) do |hsh|
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

      client, defaults = Savon::Client.new(@mrs_wsdl_url), (@defaults["mrs"] || {})

      resp = handle_response_errors do
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
      
      ## Retrieve the item element if it's available, else hsh is empty. 
      hsh = [:assign_b_number_response, :assign_b_number_result, :item].
        inject(resp.to_hash) { |rhsh, elem| rhsh[elem] || {} }
      
      handle_response_hash(hsh) do |hsh|
        d = hsh[:data]
        { :country_code => d[:cc], :area_code => d[:ndc], :vanity_number => d[:sn] }
      end
    end
    
    def delete_vanity_number!(opts)
      check_for_parameters([:vanity_number], opts)

      client, defaults = Savon::Client.new(@mrs_wsdl_url), (@defaults["mrs"] || {})

      resp = handle_response_errors do
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

      ## Retrieve the item element if it's available, else hsh is empty. 
      hsh = [:delete_b_number_response, :delete_b_number_result, :item].
        inject(resp.to_hash) { |rhsh, elem| rhsh[elem] || {} }
      
      handle_response_hash(hsh) do |hsh|
        { :deleted_vanity_number => getp(:vanity_number, opts) }
      end
    end

    def route_vanity_number!(opts)
      check_for_parameters([:vanity_number, :dest_number], opts)

      client, defaults = Savon::Client.new(@mrs_wsdl_url), (@defaults["mrs"] || {})
      resp = handle_response_errors do
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

      ## Retrieve the item element if it's available, else hsh is empty. 
      hsh = [:apply_profile_response, :apply_profile_result, :item].
        inject(resp.to_hash) { |rhsh, elem| rhsh[elem] || {} }
      
      handle_response_hash(hsh) do |hsh|
        { :vanity_number => getp(:vanity_number, opts), :dest_number => getp(:dest_number, opts) }
      end
    end
  end
end

