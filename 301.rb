require 'rubygems'
require 'spreadsheet'

book = Spreadsheet.open('c.xls')

mySheet = book.worksheet(2)

class String
  def valid_integer?
    true if Integer self rescue false
  end
end

def shortlink(source, target)
	catlink="/category/index.jsp?categoryId="
	return (source.valid_integer? ? catlink + source : source) + ";${StandardPath}" + target + ";301;;;true;false;"
end

File.open('content301.csv', 'w+') do |f|
	f.puts "ShortURL;TargetURL;StatusCode;ValidFrom;ValidTo;Enabled;Default;Description;LinkGroupIDs"
	mySheet.each do |row|
		f.puts shortlink(row[1].to_s,row[13].to_s)
	end
end