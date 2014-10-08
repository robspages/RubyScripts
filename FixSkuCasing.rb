# encoding: utf-8
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'logger'

#sourceFile = "us-channel-spxShowOnEBay.xml"
sourceFile = 'c:\Users\allenr\Downloads\ExcludeFromSearch.xml'

class Nokogiri::XML::Document
	def remove_empty_lines!
		self.xpath("//text()").each { |text| text.content = text.content.gsub(/\n(\s*\n)+/,"\n") }; self
	end
end

class Logger
	## used for debugging - similar to 'puts' but toggles with the second param
	def printl(str, debug=false)
		if (debug)
			puts str.to_s
			self.info str.to_s
		end
	end
end

class String
	def is_number?
		true if Float(self) rescue false
	end
end

def isNumericSku(sku)
	s = sku[3..sku.length]
	return s.is_number?
end


# used to beginTag and endTag to build HTML tags in a string
def begintag(name, attributes=[])
	attribs = ""
	if (!attributes.empty)
		attributes.each do |(key,value)|  
			attribs = " #{key.strip}=\"#{value.strip}\""
		end
	end
	return "<" + name.strip + " " + attribs + ">"
end

def endtag(name)
	return "</#{name.strip}>"
end
### 

## rolls up the stuff for copying one node/nodeset to another 
def createNewSet (source)#, depth=1,clean=false)
	ns = source.clone
	ns.root.children.remove
	ns.encoding = 'UTF-8'
	return ns
end


def newLog(filename)
	File.delete(filename) if File.exist?(filename)
	log = Logger.new(filename)
	log.level = Logger::INFO
	return log
end 


## seperates offers in 1 export into a file for things to be deleted and another to update the remaining - not fully baked
def GetKeepers(filename)
	log = newLog('log.txt')
	debug = true
	root = getRoot(filename, debug)
	offers = getOffers(root)
	cp = offers.dup

	numLow = 0;
	numUp = 0;
	commonNodesToRemove = ['custom-attributes','offered-product','product-type', 'online', 'available']
	uNodesToRemove = [ 'images', 'short-description', 'long-description']

	enfinityHeader ='<?xml version="1.0" encoding="UTF-8"?>
	<enfinity
	xsi:schemaLocation="http://www.intershop.com/xml/ns/enfinity/6.5/xcs/impex catalog.xsd
	http://www.intershop.com/xml/ns/enfinity/6.5/core/impex-dt dt.xsd"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns="http://www.intershop.com/xml/ns/enfinity/6.5/xcs/impex"
	xmlns:xml="http://www.w3.org/XML/1998/namespace"
	xmlns:dt="http://www.intershop.com/xml/ns/enfinity/6.5/core/impex-dt"
	major="6" minor="1" family="enfinity" branch="enterprise" build="6.6.54.22.14">'

	lowercase = []
	lowercase.push enfinityHeader
	uppercase = []
	uppercase.push enfinityHeader
	

	badskus = ["38-1311§§§ROUGE", "38-1311§§§SAPPH", "38-652§§§SAPPH", "38-1312§§§BLACK", "38-1312§§§ROUGE", "38-1312§§§SAPPH", "38-032§§§COCOA", "38-032§§§BARE", "38-032§§§BLACK", "38-004§§§COCOA", "38-004§§§BLACK", "38-004§§§BARE", "38-618§§§WHITE", "38-618§§§BLACK", "38-1154§§§BLACK", "38-010§§§MIDNT-SLD", "38-914§§§DVEGR", "38-012§§§BK-CC-SLD", "38-1837§§§BLACK", "38-010§§§BITTER", "38-010§§§BLACK-FLT", "38-913§§§DVEGR", "38-010§§§BLACK-SLD", "38-010§§§MIDNT-FLT", "38-010§§§CHINO-FLT", "38-128§§§RYPLM", "38-1128§§§BLACK", "38-1341§§§BERRY", "38-1591§§§BKBT", "38-652§§§BLACK", "38-010§§§CHINO-SLD"] 

	c = offers.count
	l = c
	offers.each do |offer|
		commonNodesToRemove.each do |node|
			log.printl "removing #{node}", debug
			if offer.at("#{node}")
				offer.at("#{node}").remove
			end
		end
		sku =  offer.at("sku/text()").to_s
		log.printl sku,debug

		if badskus.include? sku.upcase
			log.printl "#{sku} is a bad sku, skipping"
		else
			if !isNumericSku(sku)
				if sku != sku.upcase
					
					fixedSku = offer.at("sku").content.to_s.upcase()

					up = offers.at("offer[@sku='#{fixedSku}']")
					if up != nil
						commonNodesToRemove.each do |node|
							log.printl "removing #{node}", debug
							if up.at("#{node}")
								up.at("#{node}").remove
							end
						end			
						log.printl up.to_s, debug
						log.printl "found uppercase version of #{sku}",debug
						uppercase.push up.to_s
						numUp = numUp + 1
					else
						log.printl "did not find uppercase version of #{sku}", debug
					end

					offer.at("sku").content = fixedSku
					
					uNodesToRemove.each do |node|
						log.printl "removing #{node}", debug
						if offer.at("#{node}")
							offer.at("#{node}").remove
						end
					end
					lowercase.push offer.to_s
					numLow = numLow +1
				end # uppercase exists?
			else
				log.printl "#{sku} is numeric, skipping"
			end
		end

		l = l - 1
		log.printl "#{l} out of #{c} remaining" , debug
	end #offers

	lowercase.push "</enfinity>"
	uppercase.push "</enfinity>"

	log.printl "total lowercase: #{numLow}", debug
	log.printl "total uppercase: #{numUp}", debug

	ouputFile('updates.xml', lowercase.join(""))
	ouputFile('deletes.xml', uppercase.join(""))
end

def ouputFile(name, data)
	File.open(name,'w') {|f| f << data.gsub(/\n\s+\n/, "\n") } #.to_xml.to_s }
end

## gets a collection of Offers (products) from an Enfinity Product XML file
def getOffers(root, xp="//xmlns:offer", debug=true)
	offers = root.xpath(xp)
	#printl offers.count().to_s + " offers found",debug
	return offers
end

## opens an XML document, sets the default encoding and returns the nodeset within the document
def getRoot(filename, debug=false)
	root = Nokogiri::XML(open(filename))
	root.encoding = 'UTF-8'
	#printl "it's open",debug
	return root
end

## takes a collection (nameArray) of node name to remove from nodeset - but working yet
def CleanUp(nodeset, nameArray)
	nodeset.each do |node|
		nameArray.each do |name|
			node.at(name).remove
		end
	end
	return nodeset
end

def getDuplicateOffers(filename)
	#filename = ARGV[0]
	debug = true
	root = getRoot(filename, debug)
	offers = getOffers(root)
	log = newLog("#{filename[0..filename.length-5]}-dupes.txt")

	log.info "Checking #{filename}"

	offers.each do |offer|
		sku = offer.at("sku/text()").to_s
		log.info "checking #{sku}"
		r = offers.search("offer[@sku='#{sku}']")
		log.info r.count 
		if (r.count>1)
			log.info "#{sku} has duplicate in #{filename}"
		end
	end
end

## creates a new Enfinity Product XML for matching products and adds a custom attribute group to them - WORKS! 
def excludeFromSearch(filename, debug)
	root = getRoot(filename,debug)
	upList = root.clone
	upList.root.children.remove
	
	#root.root.collect_namespaces!
	offers = getOffers(root, "//xmlns:offer", true)
	
	customAttributes = Nokogiri::XML::Node.new "custom-attributes", upList
	customAttributes << addCustomAttrib(upList, "spx_ShowOnSpanx", "No")
	customAttributes << addCustomAttrib(upList, "spx_ShowOnEBay", "Yes")
	customAttributes << addCustomAttrib(upList, "ExcludeFromSearchIndex", "true", "boolean")

	offers.each do |offer|
		printl offer, false
		exclude = offer.at('custom-attributes/custom-attribute[@name="spx_ShowOnSpanx"]')
		if(exclude != nil)
			if(exclude.text == "No")
				printl "exclude.text == \"No\""
				node = Nokogiri::XML::Node.new("offer", upList)
				node["sku"] = offer["sku"]
				node << offer.at("sku")
				node << offer.at("name")
				node << customAttributes.clone
				upList.root << node
			end
		end
	end
	File.open('exclude.xml','w') {|f| f.puts upList.to_xml}
end

def showMeTheSkus(filename)
	file = filename[0..filename.length-5]
	log = newLog("sku-#{file}-log.txt")
	debug = true
	root = getRoot(filename, debug)
	offers = getOffers(root)

	File.open("#{file}-skus.txt", "w:UTF-8") do |f|     
	 	offers.each do |offer|
	 		f.puts offer.at("sku/text()").to_s
		end
	end
end

## builds a custom attribute node for an Enfinity Product XML file 
def addCustomAttrib(doc, name, value, datatype="string")
	node = Nokogiri::XML::Node.new "custom-attribute", doc
	node["name"] = name	
	node["dt:dt"] = datatype
	node.content = value
	return node
end

## run your function here: 
#excludeFromSearch(sourceFile, debug=true)
GetKeepers(sourceFile)
getDuplicateOffers("deletes.xml")
getDuplicateOffers("updates.xml")
showMeTheSkus("deletes.xml")
showMeTheSkus("updates.xml")