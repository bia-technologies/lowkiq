require "rack"
require "lowkiq/web/action"
require "lowkiq/web/api"

module Lowkiq
  module Web
    HTML = Proc.new do |env|
      root_path = env['SCRIPT_NAME']
      [200, {}, [<<-HTML]]
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="UTF-8">
            <title>Lowkiq</title>
          </head>
          <body>
            <div id="root"></div>
            <script type="text/javascript">
              window.lowkiqRoot="#{root_path}";
            </script>
            <script type="text/javascript" src="#{root_path}/assets/#{VERSION}/app.js"></script>
          </body>
        </html>
      HTML
    end

    ASSETS = File.expand_path("#{File.dirname(__FILE__)}/../../assets")

    APP = Rack::Builder.new do
      map "/api" do
        use Rack::ContentType, "application/json"
        run Api
      end

      map "/assets/#{VERSION}" do
        run Rack::File.new ASSETS, { 'Cache-Control' => 'public, max-age=86400' }
      end

      use Rack::ContentType, "text/html"
      run HTML
    end

    def self.call(env)
      APP.call env
    end
  end
end
