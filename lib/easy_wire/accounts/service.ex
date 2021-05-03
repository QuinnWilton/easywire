defprotocol EasyWire.Accounts.Service do
  def get_account_for_profile(service, profile_id)
  def deposit_money(service, profile_id, amount)
end
