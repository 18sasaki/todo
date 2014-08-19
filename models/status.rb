
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
