require 'yaml'
require 'pony'
require 'mail'
require 'mongoid'

task :getmail do
  Pony.options = {
    :via => :smtp,
    :via_options => {
      :address => 'smtp.gmail.com',
      :port => '587',
      :enable_starttls_auto => true,
      :user_name => ENV['STYLUS_PALS_EMAIL_ADDR'],
      :password => ENV['STYLUS_PALS_EMAIL_PASSWD'],
      :authentication => :plain,
      :domain => 'localhost.localdomain'
    }
  }

  Mail.defaults do
  retriever_method :pop3, :address => 'pop.gmail.com', :port => 995,
    :user_name => ENV['STYLUS_PALS_EMAIL_ADDR'], :password => ENV['STYLUS_PALS_EMAIL_PASSWD'],
    :enable_ssl => true
  end
  
  Mongoid.load!('mongoid.yml', :development)
    
  class User
    include Mongoid::Document
    
    validates_uniqueness_of :number
    
    field :number, type: Integer
    field :carrier, type: String
    field :verified, type: Boolean, default: false
    field :conversation_partner, type: Integer
  end
  
  Mail.all.each do |msg|
    sender = User.find_by(number: msg.from[0].to_i)
    unless sender.verified
    
      words = msg.body.to_s.split
      if words[0].downcase == '!accept'
        email_domain = case sender.carrier
          when 'att'
            "@txt.att.net"
          when 'verizon'
            "@vtext.com"
          when 'sprint'
            "@messaging.sprintpcs.com"
          when 'tmobile'
            "@tmomail.net"
        end
        sender.update_attribute(:verified, true)
        recipient = sender.number.to_s + email_domain
        Pony.mail(:to => recipient, :subject => 'StylusPals Verified', :body => 'This number has been verified with StylusPals! Please wait while we find a stylus pal...')
        puts recipient + ': receipt sent'
      end
      
    else
    
      unless sender.conversation_partner.nil?
        words = msg.body.to_s.split
        if words[0].downcase == '!next'
          conversation_partner = User.find_by(number: sender.conversation_partner)
          sender.update_attribute(:conversation_partner, nil)
          sender.update_attribute(:last_next_time, Time.now)
          conversation_partner.update_attribute(:conversation_partner, nil)
          conversation_partner.update_attribute(:last_next_time, Time.now)
        else
          conversation_partner = User.find_by(number: sender.conversation_partner)
          email_domain = case conversation_partner.carrier
            when 'att'
              "@txt.att.net"
            when 'verizon'
              "@vtext.com"
            when 'sprint'
              "@messaging.sprintpcs.com"
            when 'tmobile'
              "@tmomail.net"
          end
          recipient = conversation_partner.number.to_s + email_domain
          outgoing_msg = msg.body.to_s[0...160] # limit text length to 160
          Pony.mail(:to => recipient, :subject => 'StylusPal', :body => outgoing_msg)
          puts sender.number.to_s + ' -> ' + recipient + ': great success'
        end
      else
        puts sender.number.to_s + ': nothing to do'
      end
      puts 'hi'
    
    end
    puts 'hello'
  end
  puts 'derp'
end

#! refactor the shit out of this
task :matchusers do
  Pony.options = {
    :via => :smtp,
    :via_options => {
      :address => 'smtp.gmail.com',
      :port => '587',
      :enable_starttls_auto => true,
      :user_name => ENV['STYLUS_PALS_EMAIL_ADDR'],
      :password => ENV['STYLUS_PALS_EMAIL_PASSWD'],
      :authentication => :plain,
      :domain => 'localhost.localdomain'
    }
  }
  
  Mongoid.load!('mongoid.yml', :development)
    
  class User
    include Mongoid::Document
    
    validates_uniqueness_of :number
    
    field :number, type: Integer
    field :carrier, type: String
    field :verified, type: Boolean, default: false
    field :conversation_partner, type: Integer
    field :last_next_time, type: DateTime, default: Time.now
  end
  
  unmatched_users = User.where(verified: true, conversation_partner: nil).asc(:last_next_time)
  
  puts unmatched_users.length
  
  while unmatched_users.length > 2
    unmatched_users.each {|usr| puts usr.number}
    first_number = unmatched_users.first.number
    first_carrier = unmatched_users.first.carrier
    last_number = unmatched_users.last.number
    last_carrier = unmatched_users.last.carrier
    unmatched_users.first.update_attribute(:conversation_partner, last_number)
    unmatched_users.last.update_attribute(:conversation_partner, first_number)
    puts unmatched_users.first.carrier
    email_domain = case first_carrier
      when 'att'
        "@txt.att.net"
      when 'verizon'
        "@vtext.com"
      when 'sprint'
        "@messaging.sprintpcs.com"
      when 'tmobile'
        "@tmomail.net"
    end
    recipient = first_number.to_s + email_domain
    Pony.mail(:to => recipient, :subject => 'StylusPals', :body => 'You have been matched with a user. Now your texts will be routed to them and vice versa.')
    email_domain = case last_carrier
      when 'att'
        "@txt.att.net"
      when 'verizon'
        "@vtext.com"
      when 'sprint'
        "@messaging.sprintpcs.com"
      when 'tmobile'
        "@tmomail.net"
    end
    recipient = unmatched_users.last.number.to_s + email_domain
    Pony.mail(:to => recipient, :subject => 'StylusPals', :body => 'You have been matched with a user. Now your texts will be routed to them and vice versa.')
    unmatched_users = User.where(verified: true, conversation_partner:nil)
  end
end
