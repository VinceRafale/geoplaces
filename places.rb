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
    slim :index
  end

  get '/api/places' do
    Places.find.to_a.map{|p| from_bson_id(p)}.to_json
  end

  post '/api/places' do
    Places.insert(params[:place])
    Places.find('_id' => params[:id])
  end

  put '/api/places/:id' do
    data = JSON.parse(request.body.read)
    Places.update(param_id, {name: data['name'], address: data['address']})
    Places.find('_id' => params[:id])
  end

  delete '/api/places/:id' do
    Places.remove(param_id)
  end

  def param_id 
    {'_id' => to_bson_id(params[:id])} 
  end
  def to_bson_id(id) BSON::ObjectId(id) end
  def from_bson_id(obj) obj.merge({'_id' => obj['_id'].to_s}) end
end