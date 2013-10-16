class ContactController < ApplicationController
  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.new(params[:contact])

    if @contact.valid?
      ContactMailer.contact_form_message(@contact).deliver

      flash[:success] = t('contacts.thanks')

      redirect_to root_url
    else
      render 'new'
    end
  end
end
