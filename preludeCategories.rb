require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'logger'
require_relative "robsUtilities"


# Source File?
sourceDir = 'C:\Users\allenr\Projects\Prelude\Feeds\Init from Luma'
sourceFile = 'PRELNA_57_Content_new_all-without-cat-linksxml.xml' #'all_promos.xml'
source = "#{sourceDir}\\#{sourceFile}"


def removeCategoryLinks(filename)
	log = newLog('prelCats_log.txt')
	debug = true
	root = getRoot(filename, debug)
	contents = getOffers(root, "//Content", debug)

	contents.each do |content|
		content.xpath('category-links').remove
	end

	outputFile('prel-content-no-cats.xml', root.to_xml)
end


removeCategoryLinks(source)