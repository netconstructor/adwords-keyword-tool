class Credential
  include Mongoid::Document
  field :email
  field :password
  field :developer_token
  validates_presence_of :email
  attr_accessible :email, :password, :developer_token

  def auth_token
    return @auth_token if @auth_token
    auth_token = authenticate(self.email, self.password)
  end

  def user_agent
    user_agent = 'Example Code from http://github.com/fortuity/adwords-keyword-tool'
  end

  private

  def authenticate(email, password)
    # requires google-client_login gem
    login = ClientLogin.new(email, password, :accountType => 'GOOGLE', :service => 'adwords')
    login.token
  end

end