require "httparty"
require "json"
require "fileutils"

url = "https://lscluster.hockeytech.com/feed/index.php?feed=statviewfeed&view=players&season=90&team=403&position=goalies&rookies=0&statsType=standard&rosterstatus=undefined&site_id=3&first=0&limit=20&sort=points&league_id=4&lang=en&division=-1&conference=-1&qualified=all&key=ccb91f29d6744675&client_code=ahl&league_id=4&callback=angular.callbacks._4"

FileUtils.mkdir_p("output")
response = HTTParty.get(url)
jsonp = response.body
File.write("output/raw_goalie_response.txt", jsonp)

json_start = jsonp.index("(")
json_end = jsonp.rindex(")")
json = jsonp[(json_start + 1)...json_end]
data = JSON.parse(json)
File.write("output/parsed_goalie_data.json", JSON.pretty_generate(data))

raw_entries = data[0]["sections"][0]["data"]
goalies = raw_entries.map { |entry| entry["row"] }
  .reject { |g| g["name"].strip.downcase.include?("empty net") || g["name"].strip.downcase.include?("totals") }

cleaned = goalies.map do |g|
  {
    name: g["name"],
    gp: g["games_played"].to_i,
    min: g["minutes_played"],  # raw "MM:SS" string
    ga: g["goals_against"].to_i,
    so: g["shutouts"].to_i,
    gaa: g["goals_against_average"].to_f,
    w: g["wins"].to_i,
    l: g["losses"].to_i,
    ot: g["ot_losses"].to_i,
    sv_percent: g["save_percentage"].to_f
  }
end

File.write("output/reign_goalies.json", JSON.pretty_generate(cleaned))
puts "✅ Saved #{cleaned.size} goalie stats to output/reign_goalies.json"
