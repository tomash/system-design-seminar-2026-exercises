require 'sinatra'
require 'faraday'

set :port, ENV.fetch("PORT", 4500)
# 4567 is the default but no app will be there, so should return 500 and remove the backend from the list
BACKENDS = ['http://localhost:4567', 'http://localhost:4568', 'http://localhost:4569', 'http://localhost:4570']
ACTIVE_BACKENDS = BACKENDS.dup
$index = 0

def next_backend
  backend = ACTIVE_BACKENDS[$index % ACTIVE_BACKENDS.size]
  $index += 1
  backend
end

# Catch all routes
[:get, :post, :put, :patch, :delete].each do |method|
  send(method, '*') do
    backend = next_backend
    target = "#{backend}#{request.fullpath}"
    
    conn = Faraday.new(url: target)
    resp = conn.send(request.request_method.downcase) do |req|
      req.headers = request.env.select { |k,_| k.start_with?('HTTP_') }
                             .transform_keys { |k| k.sub('HTTP_', '').gsub('_', '-') }
      req.body = request.body.read if ['POST','PUT','PATCH'].include?(request.request_method)
    end

    status resp.status
    headers resp.headers
    body resp.body
  rescue Faraday::ConnectionFailed
    ACTIVE_BACKENDS.delete(backend)
    status 500
    body "Backend #{target} is not available"
  end
end