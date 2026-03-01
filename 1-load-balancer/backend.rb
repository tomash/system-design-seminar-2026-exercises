require 'sinatra'

set :port, ENV.fetch("PORT", 4567)

get '/' do
  "Backend number: #{ENV.fetch("BACKEND_NUMBER", "no backend number")} on port #{ENV.fetch("PORT", 4567)}"
end