module BillsHelper
  def latest_bill_text(bill)
    if bill.text
      bill.text.last['Text']
    else
      'No bill text available.'
    end
  end
end
