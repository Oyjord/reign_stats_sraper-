require "httparty"
require "json"
require "fileutils"

url = "https://lscluster.hockeytech.com/feed/index.php?feed=statviewfeed&view=players&season=90&team=403&position=skaters&rookies=0&statsType=standard&rosterstatus=undefined&site_id=3&first=0&limit=20&sort=points&league_id=4&lang=en&division=-1&conference=-1&key=ccb91f29d6744675&client_code=ahl&league_id=4&callback=angular.callbacks._4"

FileUtils.mkdir_p("output")

response = HTTParty.get(url)
jsonp = response.body
File.write("output/raw_response.txt", jsonp)

json_start = jsonp.index("(")
json_end = jsonp.rindex(")")
if json_start.nil? || json_end.nil?
  puts "❌ Failed to locate JSONP wrapper"
  exit 1
end

json = jsonp[(json_start + 1)...json_end]

begin
  data = JSON.parse(json)
rescue => e
  puts "❌ JSON parse error: #{e}"
  exit 1
end

unless data.is_a?(Array) && data[0].is_a?(Hash)
  puts "⚠️ Unexpected top-level structure"
  File.write("output/parsed_data.json", JSON.pretty_generate(data))
  exit 1
end

begin
  players = data[0]["sections"][0]["data"].map { |entry| entry["row"] }
rescue => e
  puts "❌ Failed to extract player rows: #{e}"
  File.write("output/parsed_data.json", JSON.pretty_generate(data))
  exit 1
end

cleaned = players.map do |p|
  {
    name: p["name"],
    position: p["position"],
    gp: p["games_played"].to_i,
    g: p["goals"].to_i,
    a: p["assists"].to_i,
    pts: p["points"].to_i,
    plus_minus: p["plus_minus"].to_i,
    pim: p["penalty_minutes"].to_i
  }
end

File.write("output/reign_stats.json", JSON.pretty_generate(cleaned))
puts "✅ Saved #{cleaned.size} player stats to output/reign_stats.json"
