class Places < Sinatra::Base
  include Mongo

  register Sinatra::Partial
  register Sinatra::TwitterOAuth

  # Config
  Sass::Plugin.options[:style] = :compressed
  use Sass::Plugin::Rack
  use Rack::Coffee, root: 'public', urls: '/javascripts'


  set :partial_template_engine, :slim
  
  ENV["MONGODB_URI"] = if ENV['RACK_ENV'] === 'production' 
    ENV["MONGOHQ_URL"] 
  else
    'mongodb://localhost:27017'
  end
  
  Places = MongoClient.from_uri.db('places-db').collection('places')
  Places.ensure_index([['loc', Mongo::GEO2D]])

  # Routes
  get '/' do
    # login_required
    slim :index
  end

  get '/api/places' do
    conditions = params.include?('lon') && params.include?('lat') ? {:loc => {'$near' => [params['lon'].to_f, params['lat'].to_f]}} : {}
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
    response.status = 200
  end

  def to_attr request
    data = JSON.parse(request)
    {name: data['name'], address: data['address'], loc: {lon: data['loc']['lon'].to_f, lat: data['loc']['lat'].to_f}}
  end

  def param_id 
    {'_id' => to_bson_id(params[:id])} 
  end
  def to_bson_id(id) BSON::ObjectId(id) end
  def from_bson_id(obj) obj.merge({'_id' => obj['_id'].to_s}) end
end