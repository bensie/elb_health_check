#\ -s puma

require "bundler"
Bundler.require

hostnames = Array(ENV["HEALTH_CHECK_HOSTNAMES"].to_s.split(",")).reject(&:empty?)

run -> (env) {
  ok = true

  Parallel.each(hostnames) do |hostname|
    code = Http.headers({ "Host" => hostname, "X-Forwarded-Proto" => "https" }).head("http://127.0.0.1:80/health_check").code rescue nil
    if !code.to_i.between(200, 209)
      ok = false
      raise Parallel::Kill
    end
  end

  if ok
    ["200", {"Content-Type" => "text/html"}, ["OK"]]
  else
    ["500", {"Content-Type" => "text/html"}, ["FAILED"]]
  end
}
