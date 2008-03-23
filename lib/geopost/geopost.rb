require 'geopost/geocall'

module Geo 
  class Post

    attr_accessor :code, :lat, :lng, :partial, :part, :country, :valid
  
    def initialize(obj, country=:GB)
  
      @part = nil
      @country = country.to_s.upcase
      @valid = false
      @lat = nil
      @lng = nil
      
      if obj.respond_to?(:postcode)
        validate(obj.postcode)
        geocode(@code) if @code
        obj.lat = @lat
        obj.lng = @lng
        return obj
      else
        validate(obj)
        geocode(@code) if @code
      end
  
    end
  
    private
  
    def validate(code)
      case @country.to_sym
      when :GB
        code.gsub!(/\s|\W/){}
        code.upcase!
        @part = code.split('+').first
        if code.size > 4
          @code = code.split('').insert(-4,'+').join('')
        else
          @code = (code.split('')[0..3]).join('')
        end
        @valid = true if @code.gsub(/\+/,' ').match(/GIR 0AA|[A-PR-UWYZ]([0-9]{1,2}|([A-HK-Y][0-9]|[A-HK-Y][0-9]([0-9]|[ABEHMNPRV-Y]))|[0-9][A-HJKS-UW]) [0-9][ABD-HJLNP-UW-Z]{2}/)
      when :US
        @code = code.to_s.gsub(/[aA-zZ]|\W|\s/){}
        if @code.size == 9
          @code = @code.split('').insert(5,'-').join('')
          @part = @code.split('')[0..4].join('')
        end
        @valid = true if @code.match(/(^\d{5}$)|(^\d{5}-\d{4}$)/)
      else
        @code = code
      end
    end
  
    def geocode(code)
      codes = {}
      eval File.readlines("#{GEOPOST_ROOT}/geocoded/#{country.to_s}.txt").to_s
  
      if codes[code]
        @lat = codes[code][:lat]
        @lng = codes[code][:lng]
      elsif @valid
        response = Call.new(code,@country).response
        parse(response) if response.include?('Zoom')
      elsif @lat.nil? && codes[@part]
        @lat = codes[@part][:lat]
        @lng = codes[@part][:lng]
        @partial = true
      elsif @country == "US"
        response = Call.new(@part,@country).response
        parse(response) if response.include?('Zoom')
        @partial = true
      else
        puts "#{code} not found"
      end
      
      code = @part if @partial
      unless codes[code] || @lng.nil?
        file = File.open("#{GEOPOST_ROOT}/geocoded/#{country.to_s}.txt", "a")
        file.puts "codes['#{code}'] = {:lat => '#{@lat}', :lng => '#{@lng}'}"
        file.close
      end
    end
  
  
    def parse(response,partial=false)
      codes = response.match(/nt\((.*)\),/)[1].split(', ')
      @lng = codes.first
      @lat = codes.last
      @partial = partial
    end
  end
end
