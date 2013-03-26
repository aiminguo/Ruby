require 'rubygems'
require 'watir'
require 'watir/close_all'

Watir::Browser.default = "ie"

class AutoTest
	attr_accessor :b

	def initialize
		Watir::IE.close_all
		@b = Watir::Browser.new
	end

	def close
		@b.close
	end

	def login(url,name,password)
		@b.goto(url)
		@b.maximize() 
		sleep 2 until @b.button(:name => "submit").exists?
		@b.text_field(:name => "txtUsername").set name
		@b.text_field(:name => "txtPassword").set password
		@b.button(:name => "submit").click
	end

end

describe "Automated Smoke Test" do
	before :each do
	end
	# login
	before :all do
		@qt = AutoTest.new
		@qt.login("https://tpodev11-8i.corp.homestore.net", "rdcagent" , "toptop")
		@b = @qt.b
	end

	it "should go to Contact Search and show the Result" do
		@b.link(:text => /Search for contacts/i).click
		@b.text_field(:id => "/LastName/i").set "L"
		@b.text_field(:id => "/FirstName/i").set "J"
		@b.button(:id => "/btnSearch/i").click
		grid = @b.div(:class => "grid")
		sleep 2 until grid.exists?
		grid.should exist
	end

	it "should go to Web Lead Forms and show the Grid" do
		@b.link(:text => /Web Lead Forms/i).click
		element = @b.h2(:text => "Web Lead Forms")
		sleep 2 until element.exists?
		element.should exist
	end	 

	it "should go to Income/Expense Tracker and show the Grid" do
		@b.link(:text =>/Income\/Expense Tracker/i).click
		grid = @b.div(:class => "grid")
		sleep 2 until grid.exists?
		grid.should exist
	end		
	
	it "should go to Preferences and Show MLS Connectivity Setup" do
		@b.link(:text =>/Settings/i).click
		element = @b.link(:text => "3rd Party Setup")
		sleep 2 until element.exists?
		element.should exist
		element.click
		span = @b.span(:text => "MLS Connectivity Setup")
		sleep 2 until span.exists?
		span.should exist		
	end	
	
	it "should go to Mass email page" do
		element = @b.link(:text =>/Compose Mass Email/i)
		sleep 2 until element.exists?
		element.should exist
		element.click
		@b.button(:value =>"Cancel").click		
	end	
	# log out and close browser
	after :all do
		@b.link(:text =>/Sign out/i).click	
		@qt.close
	end
end
