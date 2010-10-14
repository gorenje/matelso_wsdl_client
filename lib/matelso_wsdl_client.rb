require 'savon'
require 'base64'

module MatelsoWsdlClient

  BaseUrl = "http://www.matelso.de/Partnerbereich" unless defined?(BaseUrl)
  WsdlUrls = {
    :fax    => "#{BaseUrl}/Matelso_Click2Faxservice_v_1_0.asmx?WSDL",
    :call   => "#{BaseUrl}/Matelso_Call2callservice_v_4_0.asmx?WSDL",
    :vanity => "#{BaseUrl}/Matelso_Rufnummernservice_v2_0.asmx?WSDL",
  } unless defined?(WsdlUrls)

  class Client
    attr_accessor :partner_id, :partner_password, :partner_account
    
    # Parameter config can either be:
    #   - String (assumed to be the file name of a YAML file)
    #   - File (open file pointer the Yaml configuration file)
    #   - Hash (the contents of the Yaml file)
    def initialize(config)
      config = case config
                 when String then YAML::load(File.open(config))
                 when File   then YAML::load(config)
                 when Hash   then config.dup
               end
      
      p = getp(:partner,config)
      @partner_id       = getp(:id, p)
      @partner_password = getp(:password, p)
      @partner_account  = getp(:account, p)
      
      @fax_wsdl_url    = wsdl_url_for(:fax,config)
      @call_wsdl_url   = wsdl_url_for(:call,config)
      @vanity_wsdl_url = wsdl_url_for(:vanity,config)
      
      @defaults = { 
        "fax"    => config["fax"], 
        "call"   => config["call"], 
        "vanity" => config["vanity"]
      }
    end
    
    def check_for_parameters(req_paras, opts)
      missing_paras = req_paras.map { |a| a.to_s } - opts.keys.map { |a| a.to_s }
      raise NotEnoughParameters, "Missing required params: #{missing_paras.join(', ')}" unless missing_paras.empty?
    end
    
    # get parameter from option hash, looking for the name as either string or symbol.
    def getp(name, opts)
      opts[name.to_sym] || opts[name.to_s]
    end
    # return a value from either the defaults or options. Preference is options.
    def def_or_paras(name, defaults, opts)
      getp(name, opts) || getp(name, defaults)
    end

    def wsdl_url_for(action,config)
      ((c = getp(action,config)) && getp(:wsdl_url,c)) || getp(action,MatelsoWsdlClient::WsdlUrls)
    end
    
    def method_missing(method_id, *args, &block)
      if [:call, :vanity, :fax].include?(method_id)
        begin
          send("%s!" % method_id, *args)
          true
        rescue Savon::SOAPFault => e
          false
        end
      else
        super(method_id, *args, &block)
      end
    end
  end
  
  class NotEnoughParameters < RuntimeError ; end
end

%w(
 fax vanity call
).each { |a| require File.dirname(__FILE__) + "/matelso_wsdl_client/#{a}.rb" }
