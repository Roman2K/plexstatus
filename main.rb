require 'utils'
require 'webrick'

class Tautulli
  def initialize(uri, api_key:)
    @http = Utils::SimpleHTTP.new URI(uri).tap { |u|
      u.path = u.path.to_s.sub(%r[/+$], "") + "/api/v2"
      u.query = URI.encode_www_form out_type: "json", apikey: api_key
    }, json: true
  end

  def cmd(name)
    res = @http.get([cmd: name]).fetch "response"
    res.fetch("result") == "success" or raise \
      "unexpected response (#{res.fetch("result")}): #{res.fetch("message")}"
    res.fetch "data"
  end
end

conf = Utils::Conf.new "config.yml"
cli = Tautulli.new conf[:url], api_key: conf[:api_key]
srv = WEBrick::HTTPServer.new Port: conf[:port]
srv.mount_proc "/sesscount" do |req, res|
  unless req.path_info.empty?
    res.status = 404
    next
  end
  count = cli.cmd("get_activity").fetch("sessions").size
  res.status = 200
  res['Content-Type'] = "application/json"
  res.body = JSON.dump count
end

trap 'INT' do srv.shutdown end
srv.start
