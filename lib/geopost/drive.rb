require 'geopost/geocall'
require 'geopost/geopost'
require 'rubygems'
require 'hpricot'

module Geo
  class Drive

    attr_accessor :from, :to, :hours, :minutes, :miles

    def initialize(code1,code2)
      @from = Post.new(code1).code
      @to = Post.new(code2).code
      page = "/maps?f=d&hl=en&geocode=&time=&date=&ttype=&saddr=#{from}&daddr=#{to}&output=html"
      response = Call.new(nil,nil,{:server => 'maps.google.com', :page => page}).response
      doc = Hpricot(response)
      #@to = (doc/"#ddw_addr_area_0/span").inner_html.gsub(/,.*/,'')
      #@from = (doc/"#ddw_addr_area_1/span").inner_html.gsub(/<.*/,'')
      result = (doc/"td.timedist/div.noprint/div").inner_html
      @miles = result.gsub(/&.*/){}.to_f
      time = result.gsub(/.*11;\s/){}
      if time.include?('hour')
        time = time.gsub(/[aA-zZ]/){}.split(' ').map! {|it| it.to_i}
        @hours = time[0]
        @minutes = time[1]
      else
        @minutes = time.gsub(/[aA-zZ]/){}.to_i
      end
    end
  end
end

