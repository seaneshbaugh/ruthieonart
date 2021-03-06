class PostsController < ApplicationController
  def index
    respond_to do |format|
      format.html do
        if params[:tag].present?
          @posts = Post.tagged_with(params[:tag]).where(:visible => true).includes(:user).page(params[:page]).per(25).order('`posts`.`created_at` DESC')
        else
          @posts = Post.where(:visible => true).includes(:user).page(params[:page]).per(25).order('`posts`.`created_at` DESC')
        end
      end

      format.rss do
        @posts = Post.where(:visible => true).includes(:user).order('`posts`.`created_at` DESC')
      end
    end
  end

  def show
    @post = Post.where(:slug => params[:id], :visible => true).first

    if @post.nil?
      flash[:error] = t('messages.posts.could_not_find')

      redirect_to root_url
    end
  end
end
