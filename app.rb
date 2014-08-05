require 'json'
require 'sinatra'
require 'data_mapper'
require 'sinatra/reloader'
require 'date'

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/todo_list.db")
class Item
    include DataMapper::Resource
    property :id, Serial
    property :content, Text, :required => true
    property :done, Boolean, :required => true, :default => false
    property :created, DateTime
end
DataMapper.finalize.auto_upgrade!

#動作テスト：ここから追加
debug_counter=0
before do
 debug_counter+=1
end

get '/debug_create' do
     Item.create(:content => "Hello #{debug_counter.to_s}!",:done => [true, false].sample  ,:created => Time.now)
end

get '/debug_show' do
  Item.all.map {|r| "#{r.id}, #{r.content}, #{r.done}, #{r.created} <br>" }
end
#動作テスト：ここまで追加
get '/' do
  @items = Item.all(:order => :created.desc)
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
  if params.has_key?("ok")
    item = Item.first(:id => params[:id])
    item.destroy
    redirect '/'
  else
    redirect '/'
  end
end

post '/done' do
  item = Item.first(:id => params[:id])
  item.done = !item.done
  item.save
  content_type 'application/json'
  value = item.done ? 'done' : 'not done'
  { :id => params[:id], :status => value }.to_json
end