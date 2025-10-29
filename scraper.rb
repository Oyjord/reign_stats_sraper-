require "httparty"
require "json"
require "fileutils"

# HockeyTech feed URL (Reign skaters, sorted by points)
url = "https://lscluster.hockeytech.com/feed/index.php?feed=statviewfeed&view=players&season=90&team=403&position=skaters&rookies=0&statsType=standard&rosterstatus=undefined&site_id=3&first=0&limit=20&sort=points&league_id=4&lang=en&division=-1&conference=-1&key=ccb91f29d6744675&client_code=ahl&league_id=4&callback=angular.callbacks._4"

# Ensure output folder exists
FileUtils.mkdir_p("output")

# Fetch JSONP response
response = HTTParty.get(url)
jsonp = response.body

# Dump raw HTML/JSONP to file for inspection
File.write("output/raw_response.txt", jsonp)
puts "📄 Dumped raw response to output/raw_response.txt"

# Strip JSONP wrapper
json_start = jsonp.index("(")
json_end = jsonp.rindex(")")
if json_start.nil? || json_end.nil?
  puts "❌ Failed to locate JSONP wrapper"
  exit 1
end

json = jsonp[(json_start + 1)...json_end]

# Parse JSON
begin
  data = JSON.parse(json)
rescue => e
  puts "❌ JSON parse error: #{e}"
  exit 1
end

puts "🔍 Top-level keys: #{data.keys}"
puts "📦 data['players'] class: #{data['players'].class}"

players = data["players"]
unless players.is_a?(Array)
  puts "⚠️ Unexpected structure: 'players' is not an array"
  File.write("output/parsed_data.json", JSON.pretty_generate(data))
  puts "📄 Dumped parsed data to output/parsed_data.json for inspection"
  exit 1
end

# Extract only the fields you want
cleaned = players.map do |p|
  {
    name: "#{p["firstName"]} #{p["lastName"]}",
    position: p["position"],
    gp: p["gamesPlayed"].to_i,
    g: p["goals"].to_i,
    a: p["assists"].to_i,
    pts: p["points"].to_i,
    plus_minus: p["plusMinus"].to_i,
    pim: p["penaltyMinutes"].to_i
  }
end

# Save to file
File.write("output/reign_stats.json", JSON.pretty_generate(cleaned))
puts "✅ Saved #{cleaned.size} player stats to output/reign_stats.json"
