require 'rubygems'
require 'spreadsheet'

book = Spreadsheet.open('content301.xls')

mySheet = book.worksheet('2')
File.open('topseller.xml', 'w+') do |f|
	f.puts "ShortURL;TargetURL;StatusCode;ValidFrom;ValidTo;Enabled;Default;Description;LinkGroupIDs"
	mySheet.each do |row|
		
	end
end

class String
  def valid_integer?
    true if Integer self rescue false
  end
end

def shortlink(source, target)
	catlink="/category/index.jsp?categoryId="
	return (source.valid_integer? ? catlink + source : source) + ", ${StandardPath}" + target + ";0;;;true;false;"
end