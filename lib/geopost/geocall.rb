require 'rubygems'
require 'eventmachine'

module Geo
  class Call
  
    attr_accessor :response
  
    def initialize(param1=nil,param2=nil,specified_options={})
      default_options = {:server => 'geo.localsearchmaps.com',
                         :page => "/?zip=#{param1.to_s}&country=#{param2.to_s}"}
      options = default_options.merge specified_options
      specified_options.keys.each do |key|
        default_options.keys.include?(key) || raise(Chronic::InvalidArgumentException, "#{key} is not a valid option key.")
      end

      EM.run do
        http = EM::P::HttpClient2.connect options[:server], 80
        d = http.get options[:page]
        d.callback {		
          @response = d.content
          status = d.status
          EM.stop
        }
      end
    end
  end
end
