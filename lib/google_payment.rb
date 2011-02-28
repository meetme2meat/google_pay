require "ruby-debug"
require "lib/interface.rb"


module GooglePayment
 def gpayment
   gcheckout = GoogleCheckout.new($MERCHANT_ID,$MERCHANT_KEY)   
   gcheckout.make_payment(build_xml_cart)
 end
 
 def test_checkout
   gcheckout = GoogleCheckout.new(MERCHANT_ID,MERCHANT_KEY)     
   gcheckout.tests
 end 
end

require "lib/google_checkout"
