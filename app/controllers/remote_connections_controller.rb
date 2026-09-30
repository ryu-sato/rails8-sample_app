class RemoteConnectionsController < ApplicationController
  # GET /remote_connections/new
  def new
    @params = { protocol: "ssh", host: RemoteConnection.allowed_hosts.first, command: "hostname && whoami" }
  end

  # POST /remote_connections
  def create
    @params = connection_params
    begin
      @output = RemoteConnection.execute(**@params)
    rescue RemoteConnection::Error => e
      @error = e.message
    end
    render :new, status: (@error ? :unprocessable_content : :ok)
  end

  private
    def connection_params
      params.expect(remote_connection: %i[ protocol host port username password command ])
            .to_h.symbolize_keys
    end
end
