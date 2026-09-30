class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_current_attributes

  private
    def set_current_attributes
      Current.request_id = request.request_id
      Current.remote_ip = request.remote_ip
      Current.user_agent = request.user_agent
    end
end
