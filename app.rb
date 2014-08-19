require 'json'
require 'sinatra'
require 'data_mapper'
require 'sinatra/reloader'
require 'date'

configure do
  enable :sessions
end

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

  has n, :item_tags
end
class Tag
  include DataMapper::Resource
  property :id, Serial
  property :tag_style_id, Integer, :required => true
  property :name, Text, :required => true

  has n, :item_tags
  belongs_to :tag_style
end
class ItemTag
  include DataMapper::Resource
  property :id, Serial
  property :item_id, Integer, :required => true
  property :tag_id, Integer, :required => true

  belongs_to :item
  belongs_to :tag
end
class TagStyle
  include DataMapper::Resource
  property :id, Serial
  property :color, Text, :required => true
  property :name, Text, :required => true

  has n, :tags
end
class Status
  include DataMapper::Resource
  property :id, Serial
  property :name, Text, :required => true
end
DataMapper.finalize.auto_upgrade!

# item #
get '/' do
  @target_ids = session[:target_ids] || []
  @items      = get_items(@target_ids, false)
  @all_tags   = get_all_tags

  redirect '/new' if @items.empty?
  erb :index
end

post '/' do
  others = params[:other_tag_ids].try(:split, ',') || []
  target = params[:target_tag_id]

  @target_ids = if others.delete(target)
                  others
                else
                  others << target
                end
  session[:target_ids] = @target_ids
  @items    = get_items(@target_ids, false)
  @all_tags = get_all_tags

  erb :index
end

def get_items(target_ids, with_done_flg=false)
  base_items = Item.all(order: :created.desc)
  items = if target_ids.empty?
            base_items
          else
            target_ids.map do |tag_id|
              base_items.tag_is(tag_id)
            end.inject(:&)
          end
  (with_done_flg ? items : items.all(done: with_done_flg)) || []
end

def Item.tag_is(tag_id)
  all(Item.item_tags.tag_id => tag_id)
end

def get_all_tags
  {}.tap do |tag_set|
    Tag.all.each do |tag|
      tag_set[tag.tag_style] ||= []
      tag_set[tag.tag_style] << tag
    end
  end
end

get '/show/:id' do
  @item = Item.get(params[:id])
  erb :show
end

get '/post/?:id?' do
  @all_tags = get_all_tags

  if target_id = params[:id]
    @item    = Item.get(target_id)
    @tag_ids = ItemTag.all(:item_id => target_id).collect(&:tag_id)

    @title = "Edit todo item"
    @form_action = "/post/#{target_id}"
  else
    @title = "Add todo item"
    @form_action = "/post"
  end
  erb :form
end

post '/post/?:id?' do
  if target_id = params[:id]
    @item = Item.get(target_id)
    @item.update(:content => params[:content], :memo => params[:memo])
    ItemTag.all(:item_id => target_id).each do |item_tag_data|
      # if exist tag_id : delete from [tag_ids], or not : destroy ItemTag
      unless params[:tag_ids].delete(item_tag_data.tag_id)
        item_tag_data.destroy
      end
    end
    params[:tag_ids].each do |new_tag_id|
      ItemTag.create(:item_id => target_id, :tag_id => new_tag_id)
    end
  else
    created_item = Item.create(:content => params[:content], :memo => params[:memo], :created => Time.now)
    (params[:tag_ids] || []).each do |tag_id|
      ItemTag.create(:item_id => created_item.id, :tag_id => tag_id)
    end
  end
  redirect '/'
end

post '/delete/:id' do
  Item.get(params[:id]).destroy!
  ItemTag.all(:item_id => params[:id]).each do |item_tag_data|
    item_tag_data.destroy
  end
  redirect '/'
end

post '/done' do
  item = Item.get(params[:id])
  item.done = !item.done
  item.save
  content_type 'application/json'
  value = item.done ? 'done' : 'not done'
  { :id => params[:id], :status => value }.to_json
end
# item #


# tag #
get '/tag' do
  @tag_styles = TagStyle.all
  erb :tag_list
end

get '/tag/post/?:id?' do
  if target_id = params[:id]
    @tag = Tag.get(target_id)

    @tag_style = @tag.tag_style
    @title = "Edit Tag"
    @form_action = "/tag/post/#{target_id}"
  else
    @tag_style = TagStyle.get(params[:tag_style_id])
    @title = "Add Tag"
    @form_action = "/tag/post"
  end
  erb :tag_form
end

post '/tag/post/?:id?' do
  if target_id = params[:id]
    @tag = Tag.get(target_id)
    @tag.update(:name => params[:name], :tag_style_id => params[:tag_style_id])
  else
    Tag.create(:name => params[:name], :tag_style_id => params[:tag_style_id])
  end
  redirect '/tag'
end

post '/tag/delete/:id' do
  Tag.get(params[:id]).destroy
  ItemTag.all(:tag_id => params[:id]).each do |item_tag_data|
    item_tag_data.destroy
  end
  redirect '/tag'
end
# tag #


# tag_style #
get '/tag_style/post/?:id?' do
  if target_id = params[:id]
    @tag_style = TagStyle.get(target_id)

    @title = "Edit TagStyle"
    @form_action = "/tag_style/post/#{target_id}"
  else
    @title = "Add TagStyle"
    @form_action = "/tag_style/post"
  end
  erb :tag_style_form
end

post '/tag_style/post/?:id?' do
  if target_id = params[:id]
    @tag_style = TagStyle.get(target_id)
    @tag_style.update(:name => params[:name], :color => params[:color])
  else
    TagStyle.create(:name => params[:name], :color => params[:color])
  end
  redirect '/tag'
end

get '/tag_style/delete/:id' do
  TagStyle.get(params[:id]).destroy!
  Tag.all(:tag_style_id => params[:id]).each do |tag|
    tag.update(:tag_style_id => nil)
  end
  redirect '/tag'
end
# tag_style #


# status #
get '/status' do
  @statuses = Status.all
  erb :status_list
end

get '/status/post/?:id?' do
  if target_id = params[:id]
    @status = Status.get(target_id)

    @title = "Edit Status"
    @form_action = "/status/post/#{target_id}"
  else
    @title = "Add Status"
    @form_action = "/status/post"
  end
  erb :status_form
end

post '/status/post/?:id?' do
  if target_id = params[:id]
    @status = Status.get(target_id)
    @status.update(:name => params[:name])
  else
    Status.create(:name => params[:name])
  end
  redirect '/status'
end

post '/status/delete/:id' do
  Status.get(params[:id]).destroy
  redirect '/status'
end
# status #

helpers do
  def tag_map
    {}.tap do |tag_map|
      Tag.all(:order => :name).each do |tag|
        tag_map[tag.id] = tag.name
      end
    end
  end
end
