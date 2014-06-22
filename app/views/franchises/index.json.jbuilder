json.array!(@franchises) do |franchise|
  json.extract! franchise, :id, :integer, :integer
  json.url franchise_url(franchise, format: :json)
end
