require 'json'
require 'sinatra'
require 'data_mapper'
require 'sinatra/reloader'
require 'date'

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/todo_list.db")
class Item
  include DataMapper::Resource
  property :id, Serial
  property :parent_id, Integer
  property :content, Text, :required => true
  property :memo, Text
  property :done, Boolean, :required => true, :default => false
  property :status_id, Integer, :default => 0
  property :created, DateTime
end
class Tag
  include DataMapper::Resource
  property :id, Serial
  property :name, Text, :required => true
end
class ItemTag
  include DataMapper::Resource
  property :id, Serial
  property :item_id, Integer, :required => true
  property :tag_id, Integer, :required => true
end
class Status
  include DataMapper::Resource
  property :id, Serial
  property :name, Text, :required => true
end
DataMapper.finalize.auto_upgrade!

get '/' do
  @items = Item.all(:conditions => {done: false}, :order => :created.desc)
  redirect '/new' if @items.empty?
  erb :index
end

get '/new' do
  @title = "Add todo item"
  erb :new
end

post '/new' do
  Item.create(:content => params[:content], :created => Time.now)
  redirect '/'
end

get '/delete/:id' do
  @item = Item.first(:id => params[:id])
  erb :delete
end

post '/delete/:id' do
  Item.first(:id => params[:id]).destroy if params.has_key?("ok")
  redirect '/'
end

post '/done' do
  item = Item.first(:id => params[:id])
  item.done = !item.done
  item.save
  content_type 'application/json'
  value = item.done ? 'done' : 'not done'
  { :id => params[:id], :status => value }.to_json
end
