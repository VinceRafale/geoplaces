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

  register Sinatra::Partial
  register Sinatra::TwitterOAuth

  # Config
  set :public_folder, File.dirname(__FILE__) + '/public'
  set :view, File.dirname(__FILE__) + '/templates'
  set :partial_template_engine, :slim
  
  Places = MongoClient.new.db('places-db').collection('places')
  Places.ensure_index([['loc', Mongo::GEO2D]])

  # Routes
  get '/' do
    # login_required
    slim :index
  end

  get '/api/places' do
    conditions = params.include?('lon') && params.include?('lat') ? {:loc => {'$near' => [params['lon'].to_f, params['lat'].to_f]}} : {}
    puts "Finding with #{conditions}"
    Places.find(conditions).to_a.map{|p| from_bson_id(p)}.to_json
  end

  post '/api/places' do
    bson_id = Places.insert(to_attr(request.body.read))
    Places.find('_id' => bson_id.to_s)
  end

  put '/api/places/:id' do
    Places.update(to_attr(request.body.read))
    Places.find('_id' => params[:id])
  end

  delete '/api/places/:id' do
    Places.remove(param_id)
  end

  def to_attr request
    data = JSON.parse(request)
    {name: data['name'], address: data['address'], loc: {lon: data['lon'].to_i, lat: data['lat'].to_i}}
  end

  def param_id 
    {'_id' => to_bson_id(params[:id])} 
  end
  def to_bson_id(id) BSON::ObjectId(id) end
  def from_bson_id(obj) obj.merge({'_id' => obj['_id'].to_s}) end
end