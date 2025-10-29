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
json_start = jsonp.index("(")
json_end = jsonp.rindex(")")
json = jsonp[(json_start + 1)...json_end]
data = JSON.parse(json)

# Extract goalie rows and filter out synthetic entries
goalies = data[0]["sections"][0]["data"]
  .map { |entry| entry["row"] }
  .reject { |g| g["name"].strip.downcase.include?("empty net") || g["name"].strip.downcase.include?("totals") }

# Convert "MM:SS" to float minutes
def parse_minutes(str)
  return 0.0 unless str && str.include?(":")
  min, sec = str.split(":").map(&:to_i)
  min + (sec / 60.0)
end

# Normalize fields
cleaned = goalies.map do |g|
  {
    name: g["name"],
    gp: g["games_played"].to_i,
    min: g["minutes"],
    ga: g["goals_against"].to_i,
    so: g["shutouts"].to_i,
    gaa: g["goals_against_average"].to_f,
    w: g["wins"].to_i,
    l: g["losses"].to_i,
    ot: g["overtime_losses"].to_i,
    sv_percent: g["save_percentage"].to_f
  }
end

# Save to file
File.write("output/reign_goalies.json", JSON.pretty_generate(cleaned))
puts "✅ Saved #{cleaned.size} goalie stats to output/reign_goalies.json"
