load "lib/google_checkout.rb"
$MERCHANT_ID  = "241441529499501"
$MERCHANT_KEY = "UQrArfl-QN1KUWDIy6v_Dg"

class GooglePay < GoogleCheckout
  
  def initialize(merchant_id,merchant_key,continue_url=nil)
    super(merchant_id,merchant_key,continue_url)
  end
end
require "lib/google_payment"
include GooglePayment
