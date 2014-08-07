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

# item #
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

post '/delete/:id' do
  Item.first(:id => params[:id]).destroy
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
# item #


# tag #
get '/tag' do
  @tags = Tag.all(:order => :name)
  erb :tag_list
end

get '/tag/post/?:id?' do
  if target_id = params[:id]
    @title = "Edit tag"
    @tag = Tag.first(:id => target_id)
    @form_action = "/tag/post/#{target_id}"
  else
    @title = "Add tag"
    @form_action = "/tag/post"
  end
  erb :tag_form
end

post '/tag/post/?:id?' do
  if target_id = params[:id]
    @tag = Tag.first(:id => target_id)
    @tag.update(:name => params[:name])
  else
    Tag.create(:name => params[:name])
  end
  redirect '/tag'
end

post '/tag/delete/:id' do
  # TODO: destroy TagItem, too.
  Tag.first(:id => params[:id]).destroy
  redirect '/tag'
end
# tag #


# status #
get '/status' do
  @statuses = Status.all
  erb :status_list
end

get '/status/post/?:id?' do
  if target_id = params[:id]
    @title = "Edit status"
    @status = Status.first(:id => target_id)
    @form_action = "/status/post/#{target_id}"
  else
    @title = "Add status"
    @form_action = "/status/post"
  end
  erb :status_form
end

post '/status/post/?:id?' do
  if target_id = params[:id]
    @status = Status.first(:id => target_id)
    @status.update(:name => params[:name])
  else
    Status.create(:name => params[:name])
  end
  redirect '/status'
end

post '/status/delete/:id' do
  Status.first(:id => params[:id]).destroy
  redirect '/status'
end
# status #

