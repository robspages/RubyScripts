require 'find'
require 'pathname'

in_path = 'C:\Users\allenr\Downloads\dats\\'
out_path = 'C:\Users\allenr\Downloads\xmls\\'
Find.find(in_path) do |file|
	fname = File.basename(file)#, File.extname(file))
	puts "old name: #{fname}"
	if fname.include?("dat") && fname != 'dats'
		xml = fname.index(".xml_")
		nname = fname[0..xml+3]
		puts "new name: #{nname}"
		if !Pathname(out_path + nname).exist?
			File.rename( file, out_path + nname )
		else
			puts "#{nname} Already Exists!"
		end
	else
		puts "no .dat in #{file}"
	end
end