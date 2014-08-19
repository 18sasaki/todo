
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

class Tag
  def self.get_tag_set
    {}.tap do |tag_set|
      Tag.all.each do |tag|
        tag_set[tag.tag_style] ||= []
        tag_set[tag.tag_style] << tag
      end
    end
  end
end
