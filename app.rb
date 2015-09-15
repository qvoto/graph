require 'sinatra'
require 'sinatra/json'
require 'faraday'
require 'json'

require_relative 'lib/aggregator'
require_relative 'lib/answer'
require_relative 'lib/exceptions'
require_relative 'lib/typeform'

configure do
  set :protection,  except: [:frame_options]
  set :environment, ENV['QVOTO_PRO'] ? :production : :development

  if settings.environment == :production
    set :qvoto_host, 'http://qvoto-graph.heroku.com'
  else
    require 'pry'
    set :qvoto_host, 'http://localhost:4567'
  end
end

before do
  headers 'Access-Control-Allow-Origin'  => '*',
          'Access-Control-Allow-Methods' => [ 'OPTIONS', 'GET', 'POST' ]
end

get '/assets/lib.js' do
  send_file File.join(__dir__, 'assets/lib.js')
end

get '/assets/style.css' do
  send_file File.join(__dir__, 'assets/style.css')
end

get '/graph' do
  answer = QVoto::Answer.find_by_quid(params[:quid])

  if answer.error
    erb :error
  elsif request.accept.map(&:entry).include?('application/json')
    content_type :json
    json answer.to_json
  else
    erb :graph, locals: { answer: answer }
  end
end
