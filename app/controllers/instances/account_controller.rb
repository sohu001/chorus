module Instances
  class AccountController < ApplicationController
    def show
      present Instance.find(params[:instance_id]).account_for_user(current_user)
    end

    def create
      present updated_account, :status => :created
    end

    def update
      present updated_account, :status => :ok
    end

    def destroy
      instance = Instance.unshared.find(params[:instance_id])
      instance.account_for_user(current_user).destroy
      render :json => {}
    end

    private

    def updated_account
      instance = Instance.unshared.find(params[:instance_id])

      account = instance.accounts.find_or_initialize_by_owner_id(current_user.id)
      account.attributes = params[:account]
      Gpdb::ConnectionChecker.check!(instance, account)
      account.save!
      account
    end
  end
end