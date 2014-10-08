# encoding: utf-8
require 'rubygems'
require 'watir-webdriver'

class Automator 
	attr_accessor :browser
	attr_accessor :startingURL
	attr_accessor :user
	attr_accessor :pass
	attr_accessor :org
	attr_accessor :steps
	attr_accessor :skus
	attr_accessor :skuCount
	attr_accessor :promos

	def initialize(server)
		@browser = Watir::Browser.new
		@startingURL = server #"https://spxna-sectst02-edit.us.gspt.net"
		@user = "admin"
		@pass = "spxnaUat"
		@org = "SPXNA"
		@steps = {}
	end 
	
	def getSkuArray(filename)
		deleteSkus = []
		puts Dir.pwd
		File.open("#{Dir.pwd}/#{filename}", 'r:UTF-8').each_line do |line|
			deleteSkus.push line
		end
		@skus = deleteSkus
		return deleteSkus
	end 

	def login(user, pass, org)
		self.getPage("Operations")
		@browser.text_field(:id=>'LoginForm_Login').when_present.set user
		@browser.text_field(:id=>'LoginForm_Password').when_present.set pass
		@browser.text_field(:id=>'LoginForm_RegistrationDomain').when_present.set org
		@browser.form(:name=>'LoginForm').submit()

		if (browser.div(:class=>'message').exists?)
			return false
		else
			return true
		end
	end

	def addStep(args)
		@steps[args[0].to_s] = args.slice(1, args.length)
	end

	def getPage(url)
		@browser.goto "#{@startingURL}/#{url}"
	end

	def setChannel(text)
		form = @browser.form(:name=>"ChannelSelectForm")
		form.select_list(:name=>"ChannelID").select text
	end

	def getPromoArray(filename)
		promos = []
		File.open("#{Dir.pwd}/#{filename}", 'r:UTF-8').each_line do |line|
			promos.push line.strip
		end
		@promos = promos
		return promos
	end

	def doPromoSearch(fields=[])
		self.getPage("gsi/webstore/WFS/SPXNA-Site/en_US/-/USD/ViewPromotionList-ListAll") #https://spxna-lvstst05-edit.us.gspt.net/
		@browser.div(:id=>'main_footer').wait_until_present
		form = @browser.form(:name=>"PromotionSimpleSearch")
		fields[0].setFieldValue form
		form.submit
	end

	def doProductSearch(skus)
		self.getPage("gsi/webstore/WFS/SPXNA-Site/en_US/-/USD/ViewProductList-Dispatch?jumpToList=TRUE&SearchType=parametric&ErrorStatus=&ClassificationSearchEnabled=true")
		@browser.div(:id=>'main_footer').wait_until_present
	
		form = @browser.form(:name=>"ParametricSearch")
		form.textarea.set skus.join

		form.submit
	end

	def prepProducts(skus)
		self.doSearch(skus)
		#@browser.input(:name=>'PageSize_-1').when_present.click

		found = false
		@browser.form(:name=>"detailForm").table.table.rows.each_with_index do |row, index|
			if index > 0 && (row.cells[2].a.text == row.cells[2].a.text.upcase)
				row.cells[0].checkbox(:name => "SelectedProductUUID").set
				found = true
			end
		end
		if found
			@browser.input(:name=>"confirmDelete").when_present.click
			@browser.input(:name=>"delete").when_present.click
		end
	end 

	def executePublishPromo()
		promoCount = @promos.count
		puts "#{promoCount} found"
		current = 0
		@promos.each do |promo|
			field = Field.new "PromotionSearch_PromotionName", "textbox", promo.to_s
			self.doPromoSearch([field])
			found = false
			@browser.form(:name=>"promotionList").table.rows.each_with_index do |row, index|
				if index > 0 && (row.cells[7].text != "Approved")
					puts row.cells[7].text
					row.cells[1].a.click
					@browser.input(:name=>"approveNow").click
					@browser.input(:name=>"editLive").wait_until_present
				end
			end
		end
	end

	def executeDelete(incriment)
		#incriment = args[0].to_i
		skuCount = @skus.count
		current = 0
		split = @skus.each_slice(incriment).to_a
		split.each do |skus|
			self.prepProducts(skus)
		    current = current + incriment
		    puts "#{current}/#{skuCount} removed"
		end
	end

	def executeSteps()
		begin
			@steps.each do |key,value|
				if value.kind_of?(Array)
					if (value.count == 1 )
						self.send(key, value[0])
					else
						self.send(key, *value)
					end

				else
					self.send(key)
				end
			end
		rescue => e
			puts e.inspect
			puts e.backtrace
			@browser.close
		end
	end

	def runTest()
		self.login()
	end

	def exit()
		@browser.close
	end
end

class Field 
	attr_accessor :name, :type, :value

	def initialize(name, type="textbox", value=nil)
		@name = name
		@type = type
		@value = value
	end

	def setFieldValue (form)
		f = nil
		vType = "value"

		case @type
			when "textbox" || "textarea" || "password"
				f = form.text_field(:name=>@name)
				vType = "value"
			when "radio"
				f = form.radio(:name=>@name, :value=>@value)
				vType = "checked"
			when "checkbox"
				f = form.checkbox(:name=>@name, :value=>@value)
				vType = "checked"
			when "select_list"
				f = form.select_list(:name=>@name)
				vType = "select"
		end

		case vType
			when "value"
				f.when_present.set @value
			when "checked"
				f.when_present.set
			when "select"
				v.when_present.select @value
		end		
	end
end