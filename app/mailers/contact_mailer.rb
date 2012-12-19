class ContactMailer < ActionMailer::Base
  default :from => 'seaneshbaugh@gmail.com'

  def contact_form_message contact
    @contact = contact

    mail :to => 'ruthieonart@ruthieonart.com', :subject => "ruthieonart.biz Contact Form - #{@contact.subject}"
  end
end
