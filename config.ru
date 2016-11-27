#\ -s puma

require "bundler"
Bundler.require

hostnames = Array(ENV["HEALTH_CHECK_HOSTNAMES"].to_s.split(",")).reject(&:empty?)

class HealthChecker
  attr_reader :ok

  def initialize(hostnames: [])
    @ok        = true
    @hostnames = hostnames
  end

  def check
    Parallel.each(@hostnames) do |hostname|
      code = Http.headers({ "Host" => hostname, "X-Forwarded-Proto" => "https" }).head("http://127.0.0.1:80/health_check").code rescue nil
      if !code.to_i.between?(200, 209)
        @ok = false
        raise Parallel::Kill # If one fails, we don't need to wait for the rest.
      end
    end
  end
end

run -> (env) {
  ok = true

  hc = HealthChecker.new(hostnames: hostnames)
  hc.check

  if hc.ok
    ["200", {"Content-Type" => "text/html"}, ["OK"]]
  else
    ["500", {"Content-Type" => "text/html"}, ["FAILED"]]
  end
}
