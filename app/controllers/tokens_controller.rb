class TokensController < ApplicationController
  skip_before_action :authenticate!

  def create
    user = User.find_by_email params[:email]

    if user && user.authenticate(params[:password])
      @token = user.tokens.create
      render status: 201
    else
      render json: { errors: { account: 'Unauthorized' }}, status: 401
    end
  end
end
