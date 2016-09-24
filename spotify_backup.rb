require 'dotenv'
require 'httpclient'
require 'json'
require 'csv'
require 'pry'

Dotenv.load

proxy = ENV['HTTP_PROXY']
client = HTTPClient.new(proxy)

# get new token here: https://developer.spotify.com/web-api/console/get-current-user-saved-tracks/
target = 'https://api.spotify.com/v1/me/tracks'
@token = ENV['SPOTIFY_TOKEN']
@offset = 0
@limit = 50


def headers
	{
		"Accept" => "application/json",
		"Authorization" => "Bearer " + @token
	}
end

songs = [];

retry_count = 0
begin
	raw = client.get(target, { 'offset' => @offset, 'limit' => @limit}, headers).content
	json = JSON.parse(raw)

	if json.nil? || json['items'].nil?
		retry_count += 1
		puts json
		redo if retry_count < 5
	end
	json['items'].each do |s|
		song = []
		song << s['track']['name']
		song << s['track']['album']['name']
		
		s['track']['artists'].each { |artist| song << artist['name'] }
		songs << song
	end
	@offset += @limit

	puts @offset
	retry_count = 0
end while @offset < json['total'].to_i


CSV.open('songs.csv', 'w') do |csv|
	songs.each { |s| csv << s }
end
