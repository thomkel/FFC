json.array!(@recruits) do |recruit|
  json.extract! recruit, :id, :integer, :integer
  json.url recruit_url(recruit, format: :json)
end
