#\ -s puma
require "json"
require "bundler"
Bundler.require

hostnames = Array(ENV["HEALTH_CHECK_HOSTNAMES"].to_s.split(",")).reject(&:empty?)

run -> (env) {
  results = Parallel.map(hostnames) do |hostname|
    code = Http.headers({ "Host" => hostname, "X-Forwarded-Proto" => "https" }).head("http://0.0.0.0:80/health_check").code rescue nil
    check = code.to_i.between?(200, 209) ? :success : :failure
    [hostname => { status: code, check: check }]
  end.flatten

  req = Rack::Request.new(env)
  hostnames_allowed_to_fail = Array(req.params["allowed_to_fail"].to_s.split(",")).reject(&:empty?)
  hostnames_must_succeed = Array(req.params["must_succeed"].to_s.split(",")).reject(&:empty?)

  filtered_results = if hostnames_allowed_to_fail.any?
    results.reject { |hash| hash.detect { |k,_v| hostnames_allowed_to_fail.include?(k) } }
  elsif hostnames_must_succeed.any?
    results.select { |hash| hash.detect { |k,_v| hostnames_must_succeed.include?(k) } }
  else
    results
  end

  response_status = filtered_results.all? { |r| r[1] == :success } ? "200" : "500"

  [response_status, {"Content-Type" => "application/json"}, [JSON.dump(results)]]
}
