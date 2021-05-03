defprotocol EasyWire.Profiles.Service do
  def list_profiles(service)
  def get_profiles(service, ids)
  def get_profile(service, id)
  def get_profile_from_session(service, session)
end
