module BillsHelper
  def latest_bill_text(bill)
    if bill.text
      bill.text.last['Text'] if bill.text.last
    else
      'No bill text available.'
    end
  end

  def thumbs_up_vote_count(bill)
    positive_votes = bill.votes.pluck(:points).select { |a| a.positive? }
    positive_votes.count
  end

  def thumbs_down_vote_count(bill)
    negative_votes = bill.votes.pluck(:points).select { |a| a.negative? }
    negative_votes.count
  end
end
