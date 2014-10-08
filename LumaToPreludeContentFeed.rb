# encoding: utf-8
require 'rubygems'
require 'nokogiri'
require 'logger'
require 'fileutils'
require 'mini_magick' 
require_relative "robsUtilities"


class ColorCode
	attr_accessor :name
	attr_accessor :code
	attr_accessor :description

	def to_s
		return "#{self.name}, #{self.code}, #{self.description}\n"
	end
end

class ColorManager
	attr_accessor :colorCodes

	def initialize(itemmaster)
		@colorCodes = self.getColorCodesFromItemMaster itemmaster
	end

	def getCodeByName(val)
		color = @colorCodes.select{|c| c.name.to_s == val}
		if color.count > 0
			puts color.count
			return color[0].code
		else
			return 'NA'
		end
	end 

	def getColorCodesFromItemMaster(itemmaster)
		root = getRoot(itemmaster, @debug)
		nodes = getNodes(root, "//Item", @debug)
		codes = []
		nodes.each do |node|
			id = node.at('ClientItemId/text()').to_s
			code = ColorCode.new
			code.name = id.match('\-(.*?)\-')[1]
			
			colorAttribs = node.at('ColorAttributes')
			if colorAttribs != nil 
				code.code = colorAttribs.at('Code/text()').to_s
				code.description = colorAttribs.at('Description/text()').to_s
			end
			dupes = codes.select{|c| c.name == code.name}
			if dupes.count === 0
				codes << code
			end
		end
		return codes
	end

	def to_csv(itemmaster, outputfile)
		codes = getAllColorCodes(itemmaster)
		outputFile(outputfile, codes.join(""))
	end

end

class LumaConverter
	attr_accessor :colors
	attr_accessor :catIDMap
	attr_accessor :parentCatID
	attr_accessor :debug
	attr_accessor :contentFeed
	attr_accessor :itemmaster
	attr_accessor :gec
	attr_accessor :channelID

	def initialize(newCatID, originalItemmaster, originalContentFeed, newGEC, newChannelID)
		@parentCatID = newCatID
		@log = newLog('LumaConversion_log.txt')
		@itemmaster = originalItemmaster
		@contentFeed = originalContentFeed
		@colors = ColorManager(itemmaster)
		@gec = newGEC
		@channelID = newChannelID
	end

	def convertCategories(map, outputFile)
		root = getRoot(@contentFeed, @debug)
		nodes = getNodes(root, "//Content", @debug)
		
		# loop through the existing CategoryLinks 
		nodes.each do |node|
			node['gsi_client_id'] = @gec
			node['catalog_id'] = @parentCatID 
			node['gsi_store_id'] = @channelID
			newCategories = []
			catLinks = node.xpath('CategoryLinks') # find the Cat Links within the current Content node
			catLinks.xpath('CategoryLink').each do |cat| # get a collection of Links, then loop through them
				@log.printl cat.text, @debug
				submap = map.select {|key, value| value == cat.text.to_s.strip} # get an array of hashes from the Map which have the current category
				if submap.count > 0 
					@log.printl submap, @debug
					submap.each { |key, value|
						newCategories << key # store this for later
					}
				else
					@log.printl 'no matches', @debug
				end
			end
	 		# clear out the original Category Links since they are Luma's keys 
			catLinks.remove

			# if we have new categorues to add... 
			if newCategories.count > 0
				# create a new CategoryLinks node
				parent = Nokogiri::XML::Node.new "CategoryLinks", root
				# for each new cat in the newCategories array create a new CategoryLink node
				newCategories.each do |val|
					link = Nokogiri::XML::Node.new "CategoryLink", parent
					link["catalog_id"] = @parentCatID
					link << "<value>#{val}</value>"
					# assign the new CategoryLink node to our CategoryLinks node
					parent << link
				end
				# add our CategoryLinks node to the Content node we are working with 
				node << parent
			end
		end
		outputFile(outputFile, root.to_xml)
	end
end

class ImageManager
	attr_accessor :colors
	attr_accessor :log
	attr_accessor :debug

	def initialize(colorManager)
		@colors = colorManager
		@log = newLog('ImageManager_log.txt')
		@debug = true
	end 

	def renameImages(imgType, source, target)
		Dir.glob(source + "*." + imgType).each do |f|
			original = File.basename(f, File.extname(f))
			@log.printl "orignal name = #{original}", @debug
			filename = self.createNewName(original)
		    FileUtils.cp_r(f, "#{target}/#{filename}.#{imgType}")
		end
	end

	def createNewName(originalName)
		## take the original file name, replace any underscores with hyphens so we only have 1 delimiter
		## then split it into an array based on that delimemiter
		## strip away whitespace for each value in the array
		## do not include any empty items in the array 
		filename = originalName
		broken = originalName.gsub(/_/i, "-").split("-").map(&:strip).reject(&:empty?)
		@log.printl "broken = " + broken.join(' => '), @debug

		filename = "#{broken[0].to_s}_#{@colors.getCodeByName(broken[2].to_s)}" 
		if broken[3] != nil 
			filename = filename + "_#{broken[3].to_s.downcase}"
		end
		return filename
	end

	def createSwatches(sourceFolder, targetFolder, width, height, xOffset, yOffset)
		Dir.glob(sourceFolder  + "*").each do |f|
			fname = File.basename(f).to_s
			if !fname.include? '_'
				buffer = StringIO.new(File.open("#{sourceFolder}#{fname}", "rb") { |i| i.read })
			    image = MiniMagick::Image.read(buffer)
			    image.crop("#{width}x#{height}+#{xOffset}+#{yOffset}")
			    image.write(targetFolder + File.basename(f, File.extname(f)) + "_sw.jpg")
			end
		end
	end

end

# Category Mapping "Prelude Key" => "Luma Key"
map = {
"01_01_01"=>"3_womenHoodiesAndSweatshirts",
"01_01_02"=>"3_womenJackets",
"01_01_03"=>"3_womenTees",
"01_01_04"=>"3_womenTanksBras",
"01_02_01"=>"3_womenPants",
"01_02_02"=>"3_womenPants",
"01_02_03"=>"3_womenShorts",
"01_03_01"=>"3_womenShorts",
"01_03_02"=>"3_womenShorts",
"01_04_01"=>"3_womenSneakers",
"01_04_02"=>"3_womenSneakers",
"01_04_03"=>"3_womenSandals",
"01_04_04"=>"3_womenSneakers",
"01_04_05"=>"3_womenSneakers",
"01_04_06"=>"3_womenSneakers",
"01_04_07"=>"3_womenSneakers",
"01_04_08"=>"3_womenSneakers",
"01_05_01"=>"3_womenBags",
"01_05_02"=>"3_womenWatches",
"01_05_03"=>"3_womenWatches",
"01_05_04"=>"3_womenFitnessAccesories",
"02_01_01"=>"3_menPolos",
"02_01_02"=>"3_menHoodiesAndSweatshirts",
"02_01_03"=>"3_menTops",
"02_01_04"=>"3_menTees",
"02_02_01"=>"3_menPants",
"02_02_02"=>"3_menPants",
"02_02_03"=>"3_menPants",
"02_03_01"=>"3_menBoots",
"02_03_02"=>"3_menRunningShoes",
"02_03_03"=>"3_menSandals",
"02_04_01"=>"3_menWatches",
"02_04_02"=>"3_menWatches",
"02_04_03"=>"3_menFitnessAccesories",
"02_04_04"=>"3_menWatches",
"03_01_01"=>"3_womenRunningShoes",
"03_01_02"=>"3_womenSneakers",
"03_01_03"=>"3_womenSandals",
"03_02_01"=>"3_menBoots",
"03_02_02"=>"3_menRunningShoes",
"03_02_03"=>"3_menSandals",
"03_03_01"=>"3_menSocks",
"03_03_02"=>"3_menSocks",
"04_01_01"=>"3_womenBags",
"04_01_02"=>"3_womenWatches",
"04_01_03"=>"3_womenWatches",
"04_01_04"=>"3_womenFitnessAccesories",
"04_02_01"=>"3_menFitnessAcessories",
"04_02_02"=>"3_menWatches",
"04_02_03"=>"3_menBags",
"04_02_04"=>"3_menWatches"}

contentFeedOutputFileName = 'PRELNA_57_Content_with_ConvertedCategories.xml'
## convertLuma(source, map, parentCatID)

itemmaster = 'C:\Users\allenr\Projects\Prelude\Feeds\Init from Luma\PRELNA_57_ItemMaster_new_all.xml'
## exportColorCodestoCSV(itemmaster)

sourceFolder = 'C:/Users/allenr/Projects/Prelude/images/luma originals/'
targetFolder = 'C:/Users/allenr/Projects/Prelude/images/renamed/'

colors = ColorManager.new itemmaster
im = ImageManager.new colors
im.createSwatches(sourceFolder, sourceFolder, 30, 30, 1435, 1435)
#rename tifs 
im.renameImages("tif", sourceFolder, targetFolder)
#rename jpgs
im.renameImages("jpg", sourceFolder, targetFolder)
