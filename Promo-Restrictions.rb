# encoding: utf-8
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'logger'
require_relative "robsUtilities"


# Source File?
sourceDir = 'c:\Users\allenr\Downloads'
sourceFile = 'prod_all_promos.xml' #'all_promos.xml'
source = "#{sourceDir}\\#{sourceFile}"

$enfinityStart = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
				<enfinity
				xsi:schemaLocation="http://www.intershop.com/xml/ns/enfinity/6.6/gsi_pf_bc_promotion_impex/impex gsi_pf_bc_promotion_impex.xsd"
				xmlns="http://www.intershop.com/xml/ns/enfinity/6.6/gsi_pf_bc_promotion_impex/impex"
				xmlns:ns2="http://www.intershop.com/xml/ns/enfinity/6.5/core/impex-dt"
				xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
				xmlns:xml="http://www.w3.org/XML/1998/namespace"
				xmlns:dt="http://www.intershop.com/xml/ns/enfinity/6.5/core/impex-dt"
				major="6" minor="6" family="enfinity" branch="enterprise" build="6.6.67.29.6">'
$enfinityEnd = "</enfinity>"
$str_shipCondition = '<sub-conditions>
				<condition-descriptor-id>OrderShippingMethodCondition</condition-descriptor-id>
				<position>0</position>
				<name></name>
				<type-code>0</type-code>
				<custom-attributes>
					<custom-attribute ns2:dt="string" name="ShippingMethods">
						<value>ANY_1DAY</value>
						<value>ANY_2DAY</value>
						<value>ANY_3DAY</value>
						<value>ANY_ECON</value>
						<value>ANY_EMAIL</value>
						<value>ANY_SAKHI</value>
						<value>ANY_STD</value>
						<value>CAN_EXP</value>
						<value>CAN_STD</value>
						<value>CPC_STD</value>
						<value>INTL_EXPAC1</value>
						<value>INTL_EXPAU</value>
						<value>INTL_EXPEU1</value>
						<value>INTL_EXPEU2</value>
						<value>INTL_EXPEU3</value>
						<value>INTL_EXPEU4</value>
						<value>INTL_EXPFE1</value>
						<value>INTL_EXPFE2</value>
						<value>INTL_EXPME1</value>
						<value>INTL_EXPME2</value>
						<value>INTL_EXPRAT</value>
						<value>INTL_EXPRCN</value>
						<value>INTL_EXPRCZ</value>
						<value>INTL_EXPRDO</value>
						<value>INTL_EXPRES</value>
						<value>INTL_EXPRFI</value>
						<value>INTL_EXPRFR</value>
						<value>INTL_EXPRHU</value>
						<value>INTL_EXPRID</value>
						<value>INTL_EXPRIT</value>
						<value>INTL_EXPRJO</value>
						<value>INTL_EXPRMT</value>
						<value>INTL_EXPRMX</value>
						<value>INTL_EXPRMY</value>
						<value>INTL_EXPRNO</value>
						<value>INTL_EXPRNZ</value>
						<value>INTL_EXPRPA</value>
						<value>INTL_EXPRPH</value>
						<value>INTL_EXPRPL</value>
						<value>INTL_EXPRPR</value>
						<value>INTL_EXPRPT</value>
						<value>INTL_EXPRSE</value>
						<value>INTL_EXPRSI</value>
						<value>INTL_EXPRSK</value>
						<value>INTL_EXPRTH</value>
						<value>INTL_EXPRUK</value>
						<value>INTL_EXPRVN</value>
						<value>INTL_EXPRZA</value>
						<value>INTL_EXPSA1</value>
						<value>INTL_EXPSA2</value>
					</custom-attribute>
				</custom-attributes>
			</sub-conditions>'

$legalText = '&lt;p&gt;Offer may not be used in conjunction with the ShopRunner shipping method. If logged into ShopRunner, select a different shipping method on the Shipping page in Checkout.&lt;/p&gt;'

def isActive(nodeset)
	enddate = DateTime.parse(nodeset.at('end-date').text)
	active = nodeset.at('active').text
	return (enddate > DateTime.now) && active == 'true'
end 

def isProblemPromo(nodeset)
	problem = false
	type = nodeset.at("actions/action-descriptor-id").text
	
	if type != "ShippingPercentageOffDiscount"

		if type = "OrderPercentageOffDiscount" || "ItemPercentageOffDiscount"
			problem = checkPercentageOff(nodeset)
		end

		if type = "OrderValueOffDiscount" || "ItemValueOffDiscount"
			problem = checkDollarOff(nodeset)
		end
	end
	return problem
end

def checkDollarOff(nodeset)
	dollar = nodeset.at("action/custom-attributes/custom-attribute[@name='ValueOff']") || 0 
	min = nodeset.at("action/custom-attributes/custom-attribute[@name='ConditionalItemsMinPrice']") || 0
	return dollar >= min # false if the value of the promo is less than or equal to the min amount 
end

def checkPercentageOff(nodeset)
	percent = nodeset.at("action/custom-attributes/custom-attribute[@name='PercentageValue']")
	if percent == "100"
		return true
	else
		return false
	end
end

def correctCombinationTypes(nodeset)
	isCombineable = (nodeset.at("combinable").text == "true")
	if isCombineable
		combinations = nodeset.at('custom-attribute[@name="CombinationTypes"]')
		okay = ["FreeGiftDiscount", "HiddenGiftDiscount", "ItemPercentageOffDiscount", "ItemTargetPriceDiscount", "ItemValueOffDiscount", "MailInRebateItemPercentageOff", "MailInRebateItemTargetPrice", "MailInRebateItemValueOff", "OrderPercentageOffDiscount", "OrderValueOffDiscount", "ShippingTargetPriceDiscount", "ShippingValueOffDiscount"]

		if combinations != nil 
			puts "combinations found"
			puts combinations
			combinations.elements.each() do |node|
				if !okay.include?(node.content)
					node.remove
				end
			end
		else
			types = [] 
			types << '<custom-attribute ns2:dt="string" name="CombinationTypes">'
			okay.each do |o|
				types << "<value>#{o}</value>"
			end
			types << '</custom-attribute>'
			nodeset.at("custom-attribute[@name='displayName']").add_next_sibling types.join("")
		end
	else
		puts "not combinable"
	end
		
	return nodeset
end

def convertToSubConditions(nodeset)
	conditions = nodeset.at("rebates/condition")

	if !conditions.at("sub-conditions") #they don't exist yet
		nSub = conditions.clone
		nSub.name = "sub-conditions"
		conditions.children.remove
		conditions << "<condition-descriptor-id>OperatorAndCondition</condition-descriptor-id>
				<position>0</position>
				<name></name>
				<type-code>1</type-code>"
		conditions << nSub
	end
	return nodeset
end

def appendShipMethods(nodeset, shipMethods)
	if nodeset.at("action-descriptor-id").text != "ShippingPercentageOffDiscount" && nodeset.at("OrderShippingMethodCondition") == nil
		conditions = nodeset.at("rebates/condition")
		subs = nodeset.xpath("/rebates/condition/sub-conditions")
		if  subs != nil
			# check for existing shipping restrictions in sub-conditions
			subs.each do |sub|
				type = sub.at("action-descriptor-id").text
				if text == "OrderShippingMethodCondition"
					return nodeset
				end
			end
			promo = convertToSubConditions(nodeset)
		elsif conditions.at("action-descriptor-id").text == "OrderShippingMethodCondition"
			return nodeset
		end
		nodeset.at("rebates/condition") << shipMethods
	end
	return nodeset
end

def renamePromo(nodeset, oldname, newname)
	nodeset.attribute('id').content = newname
	nodeset.at("custom-attributes/custom-attribute[@name='displayName']").content = newname
	return nodeset
end

def changeCreator(nodeset, newname)
	c = nodeset.at("creator-id")
	if c != nil 
		c.content = "#{newname}@SPXNA"
	end
	return nodeset
end

def appendLegalText(nodeset, legal = $legalText)
	text = nodeset.at("custom-attributes/custom-attribute[@name='LegalContentMessage']") || nil
	if text != nil
		nodeset.at("custom-attributes/custom-attribute[@name='LegalContentMessage']").content = text.text + legal
	end 
	return nodeset
end

def deactivate(promo, id, log, debug)
	# change the end date to today (now) unless start date is in the future
	if DateTime.parse(promo.at("start-date").text) <= DateTime.now
		promo.at("end-date").content = DateTime.now.strftime("%d/%m/%Y %H:%M:00")
	end
	# change the active flag to false
	promo.at("active").content = "false"
	promo.at("available").content = "false"
	# change to no code promo
	if promo.at("promotion-code-definition/promotion-code-required").text == "true"
		promo.at("promotion-code-definition/promotion-code-required").content = "false"
		promo.at("promotion-code-definition/single-code").content = nil
		if promo.at("promotion-code-definition/use-promotion-code-groups").text == "true"
			promo.at("promotion-code-definition/use-promotion-code-groups").content = "false"
			if promo.at("promotion-code-definition/promotion-code-groups") != nil
				promo.at("promotion-code-definition/promotion-code-groups").content = nil
			end
		end
	end
	# add section description explaining the 
	description = promo.at("custom-attributes/custom-attribute[@name='description']").text
	promo.at("custom-attributes/custom-attribute[@name='description']").content = "ShopRunner Incompatible- deactivated; #{description}"
	return promo.to_s
end


def createUpdatedPromo(promo, id, log, debug)
	#create the new Promo
	log.printl "#{id} is problematic", debug
	
	log.printl "appeding ship methods", debug
	promo = appendShipMethods(promo, $str_shipCondition)

	log.printl "updating promo ID", debug
	promo = renamePromo(promo, id, "#{id}_SRSafe")

	log.printl "changing promo creator to Admin", debug
	promo = changeCreator(promo, 'admin')

	log.printl "adjusting Combination Types"
	promo = correctCombinationTypes(promo)

	log.printl "appending updated legal Text"
	promo = appendLegalText(promo)


# add section description explaining the 
	description = promo.at("custom-attributes/custom-attribute[@name='description']").text
	promo.at("custom-attributes/custom-attribute[@name='description']").content = "ShopRunner Ready; #{description}"
	#remove the extra namespace declarations
	pString = promo.to_s
	pString[' xmlns="http://www.intershop.com/xml/ns/enfinity/6.6/gsi_pf_bc_promotion_impex/impex" xmlns:ns2="http://www.intershop.com/xml/ns/enfinity/6.5/core/impex-dt"'] = ''

	return pString
end

def seekAndAppend(filename)
	log = newLog('SR_log.txt')
	debug = true
	root = getRoot(filename, debug)
	promos = getNodes(root, "//xmlns:promotion", debug)

	#shipMethods = Nokogiri::XML.parse($str_shipCondition)
	idListCSV = []
	idListCSV << "old, new\n"

	idOld = []
	idNew = []
	newPromo = []
	newPromo.push $enfinityStart

	oldPromo = []
	oldPromo.push $enfinityStart

	promos.each do |promo|
		id = promo.attribute("id").text #'promotion/@id/text()')
		log.printl "Inspecting #{id}...", debug

		if isActive(promo)
			log.printl "#{id} is active"

			if isProblemPromo(promo)
				newPromo.push createUpdatedPromo(promo.clone, id, log, debug) # only this part needs to have a clone.
				oldPromo.push deactivate(promo,id,log,debug)
				idListCSV << ["#{id},#{id}_SRSafe\n"]
				idOld << "#{id}\n"
				idNew << "#{id}_SRSafe\n"
			else
				log.printl "#{id} is NOT problematic", debug
			end
		else
			log.printl "#{id} is NOT Active", debug
		end
	end

	newPromo.push $enfinityEnd
	oldPromo.push $enfinityEnd

	outputFile('SRSafePromos.xml', newPromo.join(""))
	outputFile('UNSafePromos.xml', oldPromo.join(""))
	outputFile('PromoIDs.csv', idListCSV.join(""))
	outputFile('allPromosAffected.txt', idOld.concat(idNew).join(""))
	
end



def addcom(filename)
	log = newLog('SR2_log.txt')
	debug = true
	root = getRoot(filename, debug)
	promos = getNodes(root, "//xmlns:promotion", debug)
	
	newPromo = []
	newPromo.push $enfinityStart

	promos.each do |promo|
		promo <<	correctCombinationTypes(promo)
		pString = promo.to_s
		pString[' xmlns="http://www.intershop.com/xml/ns/enfinity/6.6/gsi_pf_bc_promotion_impex/impex" xmlns:ns2="http://www.intershop.com/xml/ns/enfinity/6.5/core/impex-dt"'] = ''

		newPromo.push pString
	end

	newPromo.push $enfinityEnd
	
	outputFile('SRSafePromos-new.xml', newPromo.join(""))

end

def getInActive(filename)
	log = newLog('SR_log.txt')
	debug = true
	root = getRoot(filename, debug)
	promos = getNodes(root, "//xmlns:promotion", debug)
	inactives = []
	promos.each do |promo|
		pDate = promo.at("custom-attributes/custom-attribute[@name='PublishedDate']")
		active = promo.at("active").content === "true" ? true : false 

		if pDate == nil || !active
			p = Promotion.new 
			p.id = promo['id'].to_s
			p.start_date = DateTime.strptime(promo.at('start-date').text.to_s, "%d/%m/%Y %H:%M:%S")
			p.end_date = DateTime.strptime(promo.at('end-date').text.to_s, "%d/%m/%Y %H:%M:%S")
			# if DateTime.strptime(p.end_date, "%d/%m/%Y %H:%M:%S") > DateTime.now && DateTime.strptime(p.start_date, "%d/%m/%Y %H:%M:%S") < DateTime.now
				inactives << p 
			# end
		end
	end
	outputFile('inactive-Promos.csv', inactives.join("\n"))
end

class Promotion 
	attr_accessor :id
	attr_accessor :start_date
	attr_accessor :end_date

	def to_s
		return "#{id}, #{start_date.strftime("%F")}, #{end_date.strftime("%F")}"
	end
end

getInActive(sourceDir + "\\all_promos.xml")
#seekAndAppend(source)
#addcom("SRSafePromos.xml")