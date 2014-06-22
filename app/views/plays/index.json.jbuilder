json.array!(@plays) do |play|
  json.extract! play, :id, :integer, :integer
  json.url play_url(play, format: :json)
end
