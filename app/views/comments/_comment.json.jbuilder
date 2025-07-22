json.extract! comment, :id, :status, :name, :email, :content, :created_at, :updated_at
json.url comment_url(comment, format: :json)
