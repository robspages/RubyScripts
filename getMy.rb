require 'rubygems'
require 'nokogiri'
require 'open-uri'

# You can add to this, but not subtract... 
#                0          1         2           3          4             5         6
FeedTypes = ["Content", "Image", "ItemMaster", "Price", "SKUProfile", "TopSeller", "UPC"]
rurl="http://secdevstlapp01.gspt.net/prodna/Archive/"
## check for arguments passed to the script and use those 
##                                              FT   GEC   Y   M  D
## command should look like: $> ruby getMy.rb Price SPXNA 2013 11 30 
## If they do not exist, assume someone changed the file instead.
numArgs = ARGV.count
if numArgs != 0
	if numArgs >= 5
		y = ARGV[2]
		m = ARGV[3] #'11'
		d = ARGV[4] #'22'
		gec = ARGV[1] #"SPXNA"
		ft =FeedTypes.index(ARGV[0])
		if ft == nil 
			abort "Invalid feed Type specified. Please request one of the following: #{FeedTypes.to_s}"
		end
		FType =  FeedTypes[ft]  # FeedTypes[3].to_s	

		if ARGV[5]
			rurl = ARGV[5]
		else
			rurl = rurl + "#{y}/#{m}/#{d}/EWS%7cWS/"
		end
	else
		abort "Unknown number of arguments supplied. Please give Feed Type, GEC, Year (OOOO), Month (00) and Day (00)"
	end
else
	# YYYY MM DD GEC-to-find FeedType
	y = '2013'
	m = '11'
	d = '22'
	gec = "SPXNA"
	FType = FeedTypes[3].to_s
	rurl = rurl + "#{y}/#{m}/#{d}/EWS%7cWS/"
end



def findMyFiles(gec,feed,y,m,d,rurl)
	## build the URL from the parameters
	url = rurl + feed

	## these are links on the page that we do not want to follow, list them by their display text.
	skip = ["Name","Last modified","Size","Description", "Parent Directory"]
	puts "Looking for #{feed} feeds for #{gec} on #{m}/#{d}/#{y} in #{url}" 
	
	## access url
	index = Nokogiri::HTML(open(url))
	
	## set up some data for debugging and user messages
	count = (index.css("a").count() - skip.count()).to_s
	puts "Found #{count} Files"
	x = 1
	z = 0

	## for each link on the page...
	index.css("a").each do |link|
		currentDoc = link.attr("href")	

		## if the current link isn't on the skip list
		if not skip.include?(link.text)
			puts "checking file #{x} of #{count}: #{currentDoc} (#{url}/#{currentDoc})"
			if !currentDoc.include?('.gz')
				## follow the link and read its contents 
				doc = Nokogiri::XML(open("#{url}/#{currentDoc}"))
				doc.collect_namespaces

				## search for the GEC in the doc we just opened, 
				##  the check looks in all values for all nodes
				if checkFile(doc, "//*[contains(., '#{gec}')]")
					z += 1
					puts "Found one!"
					outputFile(currentDoc, doc)
				end
			else
				puts "skipping gzipped file #{url}/#{currentDoc}"
			end
			x += 1
		end
	end
	puts "Found #{z} Files for #{gec}"
end

def checkFile(doc, chkString)
	offers = doc.xpath(chkString)
	return (offers.count > 0)
end

def outputFile(name, data)
	File.open(name,'w+') {|f| f << data.to_xml.to_s.gsub(/\n\s+\n/, "\n") }
end

## Run IT 
findMyFiles(gec, FType, y,m,d,rurl)