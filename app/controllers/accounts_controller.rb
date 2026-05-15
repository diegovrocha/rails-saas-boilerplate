class AccountsController < ApplicationController
  before_action :set_account, only: %i[show edit update switch]

  def show
    authorize @account
  end

  def edit
    authorize @account
    @account.build_address unless @account.address
  end

  def update
    authorize @account

    if @account.update(account_params)
      redirect_to account_path(@account), notice: I18n.t("flash.account_updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def switch
    authorize @account, :switch?
    session[:current_account_id] = @account.id
    redirect_to root_path, notice: I18n.t("flash.account_switched")
  end

  private
    def set_account
      @account = policy_scope(Account).find(params[:id])
    end

    def account_params
      params.expect(
        account: [
          :name, :cpf, :phone, :email,
          { address_attributes: [ :id, :zip, :street, :number, :complement, :neighborhood, :city, :state, :country ] }
        ]
      )
    end
end
