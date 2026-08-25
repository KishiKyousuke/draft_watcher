class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern if Rails.env.production?

  before_action :authenticate_basic_auth, if: -> { Rails.env.production? }

  private

  def authenticate_basic_auth
    authenticate_or_request_with_http_basic do |username, password|
      expected_username = Rails.application.credentials.dig(:basic_auth, :username).to_s
      expected_password = Rails.application.credentials.dig(:basic_auth, :password).to_s

      ActiveSupport::SecurityUtils.secure_compare(
        ::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(expected_username)
      ) & ActiveSupport::SecurityUtils.secure_compare(
        ::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(expected_password)
      )
    end
  end
end
