require 'rubygems'
require 'spreadsheet'

book = Spreadsheet.open('Jobs.xls')

mySheet = book.worksheet(0)

def create_row(domain, jobtitle)
	return domain + ";" + jobtitle + ";disabled;disabled;disabled"
end

File.open('jobs.csv', 'w+') do |f|
	mySheet.each do |row|
		f.puts create_row(row[0],row[1])
	end
end

class String
  def valid_integer?
    true if Integer self rescue false
  end
end

