require "active_support"
require "uri"
require "net/http"
require "net/https"
require "hpricot"
#require "rexml"
require "builder"
require "lib/interface"
require "lib/dummy_parser"

module Sandbox
  include Interface
  URL = "https://sandbox.google.com/checkout/api/checkout/v2/merchantCheckout/Merchant/%s".freeze
  TEST_URL = "https://%s:%s@sandbox.google.com/checkout/api/checkout/v2/request/Merchant/%s".freeze
  DIAGNOSE_URL = "https://sandbox.google.com/checkout/api/checkout/v2/merchantCheckout/Merchant/%s/diagnose".freeze
end

module Production
 include Interface 
 URL = "https://checkout.google.com/api/checkout/v2/merchantCheckout/Merchant/%s".freeze
 TEST_URL = "https://%s:%s@checkout.google.com/api/checkout/v2/request/Merchant/%s".freeze 
 DIAGNOSE_URL = "https://checkout.google.com/api/checkout/v2/merchantCheckout/Merchant/%s/diagnose".freeze
end





class GoogleCheckout 
  include  defined?(Rails) ? (Rails.env == "development" ? "Sandbox" : "Production").constantize : Kernel.const_get("Sandbox")   
 
attr_accessor :uri,:test_uri,:test_data,:xml_data,:diagnose_uri,:merchant_id,:merchant_key,:continue_shopping_url,:edit_cart_url,:merchant_private_data,:currency 
 def initialize(merchant_id,merchant_key,continue_url)
   @merchant_id =  merchant_id
   @merchant_key = merchant_key
   @continue_shopping_url = continue_url
   @uri = URI.parse URL % @merchant_id
   @test_uri = URI.parse TEST_URL % %W(#{@merchant_id} #{@merchant_key} #{@merchant_id})
   @diagonse_uri = DIAGNOSE_URL % @merchant_id
   @test_data = %Q{<hello xmlns="http://checkout.google.com/schema/2"/>}
   @contents = Array.new
   @merchant_private_data  = ''
   @currency = "USD"
 end


 def self.sandbox?
   not defined?(Rails) && Rails.env == "development"
 end

 def is_sandbox?
   self.class.sandbox?
 end

 def add_item(item)
   @xml_data =  nil

   missing_keys = [ :name, :description, :price ,:quantity].select { |key|
    !item.include? key
   }
   unless missing_keys.empty?
    raise ArgumentError,
      "Required keys missing: #{missing_keys.inspect}"
   end
   
    @contents << {:name => item[:name] ,:description => item[:description],:unit_price => item[:price],:quantity => item[:quantity]}
    item
 end
  
 def build_xml_cart
  xml = Builder::XmlMarkup.new
    xml.instruct!
      @xml_data = xml.tag!('checkout-shopping-cart', :xmlns => "http://checkout.google.com/schema/2") {
        xml.tag!("shopping-cart") {
          xml.items {
            @contents.each { |item|
              xml.item {
                if item.key?(:item_id)
                  xml.tag!('merchant-item-id', item[:item_id])
                end
                xml.tag!('item-name') {
                  xml.text! item[:name].to_s
                }
                xml.tag!('item-description') {
                  xml.text! item[:description].to_s
                }
                xml.tag!('unit-price', :currency => (item[:currency] || 'USD')) {
                  xml.text! item[:price].to_s
                }
                xml.quantity {
                  xml.text! item[:quantity].to_s
                }
              }
            }
          }
          unless @merchant_private_data.empty?
            xml.tag!("merchant-private-data") {
              @merchant_private_data.each do |key, value|
                xml.tag!(key, value)
              end
            }
          end
        }
        xml.tag!('checkout-flow-support') {
          xml.tag!('merchant-checkout-flow-support') {
            xml.tag!('edit-cart-url', edit_cart_url) if edit_cart_url
            xml.tag!('continue-shopping-url', continue_shopping_url) if continue_shopping_url

            xml.tag!("request-buyer-phone-number", false)

            # TODO tax-tables
            xml.tag!("tax-tables") {
              xml.tag!("default-tax-table") {
                xml.tag!("tax-rules") {
                  xml.tag!("default-tax-rule") {
                    xml.tag!("shipping-taxed", false)
                    xml.tag!("rate", "0.00")
                    xml.tag!("tax-area") {
                      xml.tag!("world-area")
                    }
                  }
                }
              }
            }

            # TODO Shipping calculations
            #      These are currently hard-coded for PeepCode.
            #      Does anyone care to send a patch to enhance
            #      this for more flexibility?
            xml.tag!('shipping-methods') {
              xml.tag!('pickup', :name =>'Digital Download') {
                xml.tag!('price', "0.00", :currency => currency)
              }
            }
          }
        }
      }
  end
 
  def diagnose
    diagnose_header(test_uri.path,xml_data)
  end
 
  def make_payment()
    parse diagnose,true
    parse(http_header.post(uri.path,xml_data)).get_elements_by_tag_name("redirect-url").gsub(/s+/,"")
  end
 

  def tests
    test_http_header.post(test_uri.path,test_data)
  end
 

 private
  
  def test_http_header
    set_https_header
  end
  
   
  def http_header
    set_https_header
  end
 
  def diagnose_header
    set_https_header(true)
  end 
 
  def set_https_header(diagonse=false)
    url = diagnose ? test_uri : uri
    http = Net::HTTP.new(url.host,url.port)
    http.use_ssl = true
    http.ca_path = "/etc/ssl/certs"
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http
  end
 
  #def redirect_link(response)
  #  Hpricot.parse(response)
  #  redirect_to ""
  #end
  
  #def checkout_url()
  #  
  #end
  
  def parse(response,diagnose=false)
    DummyParser.parse(response) 
  end
end
