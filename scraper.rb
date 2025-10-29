require "httparty"
require "json"
require "yaml"

config = YAML.load_file("config.yml")
url = config["feed_url"]
output_path = config["output_path"]

response = HTTParty.get(url)
jsonp = response.body

# Strip JSONP wrapper
json_start = jsonp.index("(") + 1
json_end = jsonp.rindex(")")
json = jsonp[json_start...json_end]

data = JSON.parse(json)
players = data["players"]

# Normalize
normalized = players.map do |p|
  {
    full_name: "#{p["firstName"]} #{p["lastName"]}",
    position: p["position"],
    games_played: p["gamesPlayed"].to_i,
    goals: p["goals"].to_i,
    assists: p["assists"].to_i,
    points: p["points"].to_i,
    plus_minus: p["plusMinus"].to_i,
    penalty_minutes: p["penaltyMinutes"].to_i
  }
end

# Save to file
File.write(output_path, JSON.pretty_generate(normalized))
puts "✅ Saved #{normalized.size} player stats to #{output_path}"
