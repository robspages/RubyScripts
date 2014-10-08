require 'rubygems'
require 'nokogiri'
require 'open-uri'

rurl = "http://www-spxus-secuat02-live.us.gspt.net/shop/spanx/shapewear/cat-38-catid-tn_spx_sw;pgid=Y9nEptOfsBCRp0L028iAHrT70000a9HByu1p;sid=JzuwdDTtfnawdGbyR6Dwe6nn3g5ZLc3YzmJJQd20?ab=topnav_Shapewear_Category:%2038:%20tab_spx_brand:%20Spanx"
root = Nokogiri::HTML(open(rurl))

def begintag(name, attrib=nil, value=nil)
	return "<" + name.strip + (attrib ? " #{attrib.strip}=\"#{value.strip}\"" : "") + ">"
end

def endtag(name)
	return "</#{name.strip}>"
end

def buildlink(doc)
	out = ""
	doc.css('li.ws-filter').each do |link|
		if link.children.first.name == "input"
			out += begintag("link", "name", link.content)
			out += link.children.first.attr("data-document-location")
			out += endtag("link")
		end
	end
	return out
end

File.open('links.xml', 'w+') do |f|
	f.puts begintag("root")
	root.css("a.ws-main-nav-link").each do |main|
		f.puts begintag("brand", "name", main.text)
		sub = Nokogiri::HTML(open(main.attr("href")))
		sub.css('li.ws-dropdown-list-item-level-1').each do |category|
			f.puts begintag("category", "name", category.css("span.fn").first.text)
			f.puts buildlink(Nokogiri::HTML(open(category.children.first.attr("href"))))
			if category.css("a.spx-more-filters")
				f.puts buildlink(Nokogiri::HTML(open(category.css("a.spx-more-filters").attr("href"))))
			end
			f.puts endtag("category")
		end
		f.puts endtag("brand")
	end
	f.puts endtag("root")
end