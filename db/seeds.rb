%x[rake db:data:load]

load 'user.rb'

users = User.all

users.each do |user|
  user.password = "changeme"
  user.save!
end

sysadmin_user = User.create({ :email => 'sean@seaneshbaugh.com', :password =>'changeme', :role => 'sysadmin', :first_name => 'Sean', :last_name => 'Eshbaugh' })

sysadmin_user.save!
