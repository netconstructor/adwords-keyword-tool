class Credential
  include Mongoid::Document
  field :email
  field :password
  field :developer_token
  validates_presence_of :email
  attr_accessible :email, :password, :developer_token

  def auth_token
    return @auth_token if @auth_token
    @auth_token = authenticate(self.email, self.password)
  end

  def user_agent
    user_agent = 'Example Code from http://github.com/fortuity/adwords-keyword-tool'
  end

  private

  def authenticate(email, password)
    # requires google_client_login gem (note: NOT the similar-but-older google-client_login gem)
    login_service = GoogleClientLogin::GoogleAuth.new(:accountType => 'GOOGLE', 
                                              :service => 'adwords', 
                                              :source => self.user_agent)
    login_service.authenticate(email, password)
    auth_token = login_service.auth
  end

end