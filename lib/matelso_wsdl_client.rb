require 'savon'
require 'base64'

module MatelsoWsdlClient

  BaseUrl = "https://www.matelso.de/Partnerbereich" unless defined?(BaseUrl)
  WsdlUrls = {
    :fax    => "#{BaseUrl}/Matelso_Click2Faxservice_v_1_0.asmx?WSDL",
    :call   => "#{BaseUrl}/Matelso_Call2callservice_v_4_0.asmx?WSDL",
    :vanity => "#{BaseUrl}/Matelso_Rufnummernservice_v2_0.asmx?WSDL",
    :mrs    => "#{BaseUrl}/Matelso_MRS_v_2_0.asmx?WSDL",
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
      @mrs_wsdl_url    = wsdl_url_for(:mrs,config)
      @call_wsdl_url   = wsdl_url_for(:call,config)
      @vanity_wsdl_url = wsdl_url_for(:vanity,config)
      
      @defaults = { 
        "fax"    => config["fax"], 
        "call"   => config["call"], 
        "vanity" => config["vanity"],
        "mrs"    => config["mrs"]
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
      ((c = getp(action,config)) && getp(:wsdl_url,c)) || 
        getp(action,MatelsoWsdlClient::WsdlUrls)
    end
    
    def handle_response_errors(&block)
      resp = yield
      raise MatelsoSoapError, "Soap error: #{resp.soap_fault}" if resp.soap_fault?
      raise MatelsoHttpError, "Http error: #{resp.http_error}" if resp.http_error?
      resp
    end

    def add_soap_prefix(hsh=nil, &block)
      (hsh || yield).inject({}) { |t,(key, value)| t.merge( "wsdl:#{key}" => value ) }
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

    def method_missing(method_id, *args, &block)
      if [:call, :vanity, :fax].include?(method_id)
        begin
          send("%s!" % method_id, *args)
        rescue Savon::SOAPFault => e
          false
        rescue MatelsoWsdlClient::MatelsoHttpError => e
          false
        rescue MatelsoWsdlClient::MatelsoSoapError => e
          false
        end
      else
        super(method_id, *args, &block)
      end
    end
  end
  
  class NotEnoughParameters < RuntimeError ; end
  class MatelsoHttpError < RuntimeError ; end
  class MatelsoSoapError < RuntimeError ; end
  class MatelsoFailedMe < RuntimeError ; end
end

%w(
 fax vanity call mrs
).each { |a| require File.dirname(__FILE__) + "/matelso_wsdl_client/#{a}.rb" }
