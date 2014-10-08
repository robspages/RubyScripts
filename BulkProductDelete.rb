# encoding: utf-8
require 'rubygems'
require_relative 'Automator'


##credentials = [user, password, org]
#
#UAT  
# 	a = Automator.new 'https://www-spxus-secuat02-edit.us.gspt.net'
# 	credentials = ["", "", "SPXNA"]

#LVSTST 
	a = Automator.new "https://spxna-lvstst05-edit.us.gspt.net" #TST-Vegas
	credentials = ["", "", "SPXNA"]

#ASHPRD 
#	a = Automator.new 'https://www-spxus-ashprd-edit.gsipartners.com'
#	credentials = ["", "", "SPXNA"]
a.addStep [:getSkuArray, 'deletes-skus.txt']
a.addStep [:login, *credentials]
a.addStep [:executeDelete, 7]
#a.steps.push [:runTest, '']

a.executeSteps
