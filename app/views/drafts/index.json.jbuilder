json.array!(@drafts) do |draft|
  json.extract! draft, :id, :name
  json.url draft_url(draft, format: :json)
end
