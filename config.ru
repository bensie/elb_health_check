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
    Parallel.map(@hostnames) do |hostname|
      code = Http.headers({ "Host" => hostname, "X-Forwarded-Proto" => "https" }).head("http://127.0.0.1:80/health_check").code rescue nil
      puts "#{code} from #{hostname}/health_check"
      if !code.to_i.between?(200, 209)
        status = :failed
      else
        status = :ok
      end
      status
    end
  end
end

run -> (env) {
  hc = HealthChecker.new(hostnames: hostnames)
  results = hc.check

  if results.all? { |r| r == :ok }
    ["200", {"Content-Type" => "text/html"}, ["OK"]]
  else
    ["500", {"Content-Type" => "text/html"}, ["FAILED"]]
  end
}
