json.array!(@demands) do |demand|
  json.extract! demand, :id, :integer, :integer, :integer, :integer
  json.url demand_url(demand, format: :json)
end
