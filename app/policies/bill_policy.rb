class BillPolicy < ApplicationPolicy
  def vote?
    user.present?
  end
end
