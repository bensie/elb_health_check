require "bundler"
Bundler.require

run -> (env) {
  ["200", {"Content-Type" => "text/html"}, ["OK"]]
}
