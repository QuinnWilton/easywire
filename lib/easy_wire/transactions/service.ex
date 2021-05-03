defprotocol EasyWire.Transactions.Service do
  def list_transactions(service, profile_id, page, page_size)
  def get_total_pending_transactions(service, profile_id)
  def get_total_processed_transactions(service, profile_id)
  def post_transaction(service, sender, recipient, amount)
end
