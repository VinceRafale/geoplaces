class SassHandler < Sinatra::Base
  set :views, File.dirname(__FILE__) + '/templates/sass'

  get '/css/*.css' do
    filename = params[:splat].first
    sass filename.to_sym
  end
end

class CoffeeHanlder < Sinatra::Base
  set :views, File.dirname(__FILE__) + '/templates/coffee'

  get '/js/*.js' do
    filename = params[:splat].first
    coffee filename.to_sym
  end
end

class Places < Sinatra::Base
  use SassHandler
  use CoffeeHanlder

  include Mongo

  register Sinatra::TwitterOAuth

  # Config
  set :twitter_oauth_config, key: 'VDZOBVgDzckCetx7nhkFqw', secret: 'yELPu6mcpKv37Po1GlRJSiY2nxcc2m18w9Od2UaLzcY'
  set :public_folder, File.dirname(__FILE__) + '/public'
  set :view, File.dirname(__FILE__) + '/templates'
  
  Places = MongoClient.new.db('places-db').collection('places')

  # Routes
  get '/' do
    # login_required
    @places = Places.find
    slim :index
  end

  post '/places' do
    puts params
    # Places.insert {name: 'foo', address: 'bar'}
    # redirect '/'
  end
end