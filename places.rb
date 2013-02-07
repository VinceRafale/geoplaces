class Places < Sinatra::Base
  include Mongo

  register Sinatra::Partial
  register Sinatra::TwitterOAuth

  # Config
  Sass::Plugin.options[:style] = :compressed
  use Sass::Plugin::Rack
  use Rack::Coffee, root: 'public', urls: '/javascripts'

  set :partial_template_engine, :slim
  
  if ENV['RACK_ENV'] === 'production' 
    ENV["MONGODB_URI"] = ENV["MONGOLAB_URI"] 
    set :database, 'heroku_app11665199'
    set :host,'http://geoplaces.herokuapp.com'
  else
    ENV["MONGODB_URI"] = 'mongodb://localhost:27017'
    set :database, 'place-db'
    set :host, 'http://localhost:9292/auth'
  end
  
  Places = MongoClient.from_uri.db(settings.database).collection('places')
  Places.ensure_index([['loc', Mongo::GEO2D], ['twitter_handle', Mongo::ASCENDING]])

  register Sinatra::TwitterOAuth
  set :twitter_oauth_config,  { :key => ENV['TWITTER_OAUTH_KEY'],
                                :secret   => ENV['TWITTER_OAUTH_SECRET'],
                                :callback => settings.host,
                                :login_template => {:slim => :login}}

  # Routes
  before '/*' do
    login_required unless %w(login connect auth logout).include? params[:splat].first
  end

  get '/' do
    slim :index
  end

  get '/api/places' do
    conditions = params.include?('lon') && params.include?('lat') ? {:loc => {'$near' => [params['lon'].to_f, params['lat'].to_f]}} : {}
    conditions[:twitter_handle] = user.screen_name
    puts "Finding with #{conditions}"
    Places.find(conditions).to_a.map{|p| from_bson_id(p)}.to_json
  end

  post '/api/places' do
    data = to_attr(request.body.read)
    puts "Adding record with #{data}"
    bson_id = Places.insert(data)
    Places.find('_id' => bson_id.to_s)
  end

  put '/api/places/:id' do
    data = to_attr(request.body.read).merge(param_id)
    puts "Updating #{param_id} with #{data}"
    Places.update(param_id, data)
    Places.find('_id' => params[:id])
  end

  delete '/api/places/:id' do
    puts "Removing #{param_id}"
    Places.remove(param_id)
    response.status = 200
  end

  # Helper methods
  def to_attr request
    data = JSON.parse(request)
    {
      name: data['name'], 
      address: data['address'], 
      loc: {
        lon: data['loc']['lon'].to_f, 
        lat: data['loc']['lat'].to_f
      }
    }.merge(twitter_handle)
  end
  def param_id 
    {'_id' => to_bson_id(params[:id])}.merge(twitter_handle) 
  end
  def twitter_handle
    {:twitter_handle => user.screen_name}
  end
  def to_bson_id(id) BSON::ObjectId(id) end
  def from_bson_id(obj) obj.merge({'_id' => obj['_id'].to_s}) end
end