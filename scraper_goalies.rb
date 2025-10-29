require "httparty"
require "json"
require "fileutils"

url = "https://lscluster.hockeytech.com/feed/index.php?feed=statviewfeed&view=players&season=90&team=403&position=goalies&rookies=0&statsType=standard&rosterstatus=undefined&site_id=3&first=0&limit=20&sort=points&league_id=4&lang=en&division=-1&conference=-1&qualified=qualified&key=ccb91f29d6744675&client_code=ahl&league_id=4&callback=angular.callbacks._4"

FileUtils.mkdir_p("output")
response = HTTParty.get(url)
jsonp = response.body

json_start = jsonp.index("(")
json_end = jsonp.rindex(")")
json = jsonp[(json_start + 1)...json_end]
data = JSON.parse(json)

goalies = data[0]["sections"][0]["data"].map { |entry| entry["row"] }

cleaned = goalies.map do |g|
  {
    name: g["name"],
    gp: g["games_played"].to_i,
    min: g["minutes"].to_i,
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
puts "✅ Saved #{cleaned.size} goalie stats"
