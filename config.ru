#\ -s puma
require "json"
require "bundler"
Bundler.require

hostnames = Array(ENV["HEALTH_CHECK_HOSTNAMES"].to_s.split(",")).reject(&:empty?)

run -> (env) {
  results = Parallel.map(hostnames) do |hostname|
    code = Http.headers({ "Host" => hostname, "X-Forwarded-Proto" => "https" }).head("http://127.0.0.1:80/health_check").code rescue nil
    check = code.to_i.between?(200, 209) ? :ok : :failed
    [hostname => { status: code, check: check }]
  end.flatten

  response_status = results.all? { |r| r[1] == :ok } ? "200" : "500"
  [response_status, {"Content-Type" => "application/json"}, [JSON.dump(results)]]
}
