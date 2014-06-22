json.array!(@positions) do |position|
  json.extract! position, :id, :position_name
  json.url position_url(position, format: :json)
end
