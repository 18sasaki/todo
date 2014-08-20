
get '/' do
  @target_ids    = session[:target_ids] || []
  @with_done_flg = session[:with_done_flg] || false
  @items         = Item.get_items(@target_ids, @with_done_flg)
  @tag_set       = Tag.get_tag_set
  erb :index
end

post '/' do
  others = params[:other_tag_ids].try(:split, ',') || []
  target = params[:target_tag_id]

  @target_ids = if target.empty? || others.delete(target)
                  others
                else
                  others << target
                end
  @with_done_flg = (params[:with_done_flg] == 'false')

  session[:target_ids]    = @target_ids
  session[:with_done_flg] = @with_done_flg

  @items    = Item.get_items(@target_ids, @with_done_flg)
  @tag_set  = Tag.get_tag_set

  erb :index
end

get '/show/:id' do
  @item = Item.get(params[:id])
  erb :show
end

get '/post/?:id?' do
  @tag_set = Tag.get_tag_set

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

class Item
  def self.get_items(target_ids, with_done_flg=false)
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

  def self.tag_is(tag_id)
    all(Item.item_tags.tag_id => tag_id)
  end
end
