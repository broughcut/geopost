require 'rubygems'
require 'eventmachine'

class Geopost

  attr_accessor :code, :lat, :lng, :partial, :country, :valid

  def initialize(obj, country=:GB)

    @country = country.to_s.upcase
    @valid = false
    
    if obj.class != String
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
      code.gsub!(/\s/){}
      code.upcase!
      if code.size > 4
        @code = code.split('').insert(-4,'+').join('')
      else
        @code = (code.split('')[0..3]).join('')
      end
      @valid = true if @code.gsub(/\+/,' ').match(/GIR 0AA|[A-PR-UWYZ]([0-9]{1,2}|([A-HK-Y][0-9]|[A-HK-Y][0-9]([0-9]|[ABEHMNPRV-Y]))|[0-9][A-HJKS-UW]) [0-9][ABD-HJLNP-UW-Z]{2}/)
    else
      @code = code
    end
  end

  def geocode(code)
    part = code.split('+').first
    codes = {}
    eval File.readlines("#{GEOPOST_ROOT}/geocoded/#{country.to_s}.txt").to_s

    if codes[code]
      @lat = codes[code][:lat]
      @lng = codes[code][:lng]
    elsif @valid || @country != "UK"
      response = Geocall.new(code,@country).response
      parse(response) if response.include?('Zoom')
    elsif @lat.nil? && codes[part]
      @lat = codes[part][:lat]
      @lng = codes[part][:lng]
      @partial = true
    else
      puts "#{code} not found"
    end
    
    code = part if @partial
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


class Geocall

  attr_accessor :response

  def initialize(code,country)
    EM.run do
      http = EM::P::HttpClient2.connect 'geo.localsearchmaps.com', 80
      d = http.get "/?zip=#{code}&country=#{country.to_s}"
      d.callback {		
        @response = d.content
        status = d.status
        EM.stop
      }
    end
  end
end
