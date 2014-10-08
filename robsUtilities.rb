# encoding: utf-8
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'logger'


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

def outputFile(name, data)
	File.open(name,'w') {|f| f << data.gsub(/\n\s+\n/, "\n") } #.to_xml.to_s }
end

## builds a custom attribute node for an Enfinity Product XML file 
def addCustomAttrib(doc, name, value, datatype="string")
	puts "adding custom-attribute #{name}"
	node = Nokogiri::XML::Node.new "custom-attribute", doc
	node["name"] = name	
	node["dt:dt"] = datatype
	if value.kind_of?(Array)
		value.each do |val|
			node << "<value>#{val}</value>"
		end
	else
		node.content = value
	end
	return node
end

## opens an XML document, sets the default encoding and returns the nodeset within the document
def getRoot(filename, debug=false)
	root = Nokogiri::XML(open(filename))
	root.encoding = 'UTF-8'
	#printl "it's open",debug
	return root
end

## Deprecated... move to getnodes; gets a collection of Offers (products) from an Enfinity Product XML file
def getOffers(root, xp="//xmlns:offer", debug=true)
	offers = root.xpath(xp)
	if debug
		puts offers.count().to_s + " nodes found" 
	end
	return offers
end

## Renamed getOffer gets a collection of Offers (products) from an Enfinity Product XML file
def getNodes(root, xp="//xmlns:offer", debug=true)
	nodes = root.xpath(xp)
	if debug
		puts nodes.count().to_s + " nodes found" 
	end
	return nodes
end