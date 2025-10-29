require "httparty"
require "json"
require "fileutils"

# HockeyTech goalie stats feed
url = "https://lscluster.hockeytech.com/feed/index.php?feed=statviewfeed&view=players&season=90&team=403&position=goalies&rookies=0&statsType=standard&rosterstatus=undefined&site_id=3&first=0&limit=20&sort=points&league_id=4&lang=en&division=-1&conference=-1&qualified=qualified&key=ccb91f29d6744675&client_code=ahl&league_id=4&callback=angular.callbacks._4"

# Ensure output folder exists
FileUtils.mkdir_p("output")

# Fetch and strip JSONP
response = HTTParty.get(url)
jsonp = response.body
File.write("output/raw_goalie_response.txt", jsonp)

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

File.write("output/parsed_goalie_data.json", JSON.pretty_generate(data))
puts "🔍 Top-level keys: #{data[0].keys}" if data.is_a?(Array) && data[0].is_a?(Hash)

# Extract and inspect goalie rows
raw_entries = data[0]["sections"][0]["data"]
puts "📦 Total entries: #{raw_entries.size}"
puts "🔍 Sample entry keys: #{raw_entries[0].keys}" if raw_entries.any?

goalies = raw_entries.map do |entry|
  row = entry["row"]
  minutes = entry["prop"]["minutes"] rescue nil
  row.merge({ "minutes" => minutes })
end.reject do |g|
  g["name"].strip.downcase.include?("empty net") || g["name"].strip.downcase.include?("totals")
end

puts "✅ Filtered goalies: #{goalies.size}"
puts "🧪 Sample goalie: #{goalies[0]}" if goalies.any?

# Normalize fields
cleaned = goalies.map do |g|
  {
    name: g["name"],
    gp: g["games_played"].to_i,
    min: g["minutes_played"],
    ga: g["goals_against"].to_i,
    so: g["shutouts"].to_i,
    gaa: g["goals_against_average"].to_f,
    w: g["wins"].to_i,
    l: g["losses"].to_i,
    ot: g["overtime_losses"].to_i,
    sv_percent: g["save_percentage"].to_f
  }
end

File.write("output/reign_goalies.json", JSON.pretty_generate(cleaned))
puts "✅ Saved #{cleaned.size} goalie stats to output/reign_goalies.json"
