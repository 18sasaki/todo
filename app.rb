require 'json'
require 'sinatra'
require 'data_mapper'
require 'sinatra/reloader'
require 'date'

configure do
  enable :sessions
end

require_relative 'models/init'

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
  property :next_ids, Text
end
DataMapper.finalize.auto_upgrade!


helpers do
  def tag_map
    {}.tap do |tag_map|
      Tag.all(:order => :name).each do |tag|
        tag_map[tag.id] = tag.name
      end
    end
  end
end
