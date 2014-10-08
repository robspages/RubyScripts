require 'rubygems'
require 'nokogiri'
require 'open-uri'

url = "http://svn.gspt.net/phx/ph-schemas/branches/ECP1.0.1/XSD/ContentFeedV11.xsd"

doc = nokogiri::Nokogiri::XSD(open(url))

