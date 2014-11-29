
get '/status' do
  @status_set = {}.tap do |status_set|
                  Status.all.each do |status|
                    status_set[status.id.to_s] = status
                  end
                end
  erb :status_list
end

get '/status/post/?:id?' do
  @all_statuses = Status.all
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
  update_params = { name: params[:name], next_ids: (params[:next_ids].try(:join, ',') || '') }

  if target_id = params[:id]
    @status = Status.get(target_id)
    @status.update(update_params)
  else
    Status.create(update_params)
  end
  redirect '/status'
end

post '/status/delete/:id' do
  Status.delete_from_next_ids(params[:id])
  Status.get(params[:id]).destroy

  redirect '/status'
end

class Status
  def self.delete_from_next_ids(target_id)
    Status.all.each do |status|
      next if status.id == target_id
      next_id_list = status.next_ids.split(',')
      if next_id_list.delete(target_id)
        status.next_ids = next_id_list.join(',')
        status.save
      end
    end
  end
end
