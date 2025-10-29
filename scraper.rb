require "httparty"
require "json"

# HockeyTech feed URL (Reign skaters, sorted by points)
url = "https://lscluster.hockeytech.com/feed/index.php?feed=statviewfeed&view=players&season=90&team=403&position=skaters&rookies=0&statsType=standard&rosterstatus=undefined&site_id=3&first=0&limit=20&sort=points&league_id=4&lang=en&division=-1&conference=-1&key=ccb91f29d6744675&client_code=ahl&league_id=4&callback=angular.callbacks._4"

# Fetch JSONP response
response = HTTParty.get(url)
jsonp = response.body

# Strip JSONP wrapper
json_start = jsonp.index("(") + 1
json_end = jsonp.rindex(")")
json = jsonp[json_start...json_end]

# Parse JSON
data = JSON.parse(json)
players = data["players"]

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
