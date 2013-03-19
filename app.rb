require 'sinatra'
require 'pony'      #see if unnecessary
require 'mail'
require 'mongoid'

enable :sessions

Pony.options = {
  :via => :smtp,
  :via_options => {
    :address => settings.address,
    :port => settings.port,
    :enable_starttls_auto => true,
    :user_name => ENV['STYLUS_PALS_EMAIL_ADDR'],
    :password => ENV['STYLUS_PALS_EMAIL_ADDR'],
    :authentication => :plain,
    :domain => 'localhost.localdomain'
  }
}

Mail.defaults do
  retriever_method :pop3, :address => 'pop.gmail.com', :port => 995,
    :user_name => ENV['STYLUS_PALS_EMAIL_ADDR'], :password => ENV['STYLUS_PALS_EMAIL_ADDR'],
    :enable_ssl => true
end

Mongoid.load!('mongoid.yml')

class User
  include Mongoid::Document
  
  validates_uniqueness_of :number
  
  field :number, type: Integer
  field :carrier, type: String
  field :verified, type: Boolean, default: false
  field :conversation_partner, type: Integer
  field :last_next_time, type: DateTime, default: Time.now
  
  def request_verification
    email_domain = case self.carrier
      when 'att'
        "@txt.att.net"
      when 'verizon'
        "@vtext.com"
      when 'sprint'
        "@messaging.sprintpcs.com"
      when 'tmobile'
        "@tmomail.net"
    end
    
    recipient = self.number.to_s + email_domain
    Pony.mail(:to => recipient, :subject => 'Verify StylusPals', :body => 'This number has been signed up with StylusPals. To accept, reply: !accept')
  end
end

get '/' do
  erb :index
end

post '/signup' do
  user = User.new(:number => params[:number], :carrier => params[:carrier])
  if user.save
    redirect "/verify/#{user.number}"
  else
    redirect '/users'
  end
end

get '/verify/:number' do |num|
  user = User.find_by(number: num)
  user.request_verification unless user.verified
  erb :verify
end
