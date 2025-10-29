require "httparty"
require "json"
require "fileutils"

url = "https://lscluster.hockeytech.com/feed/index.php?feed=statviewfeed&view=players&season=90&team=403&position=skaters&rookies=0&statsType=standard&rosterstatus=undefined&site_id=3&first=0&limit=20&sort=points&league_id=4&lang=en&division=-1&conference=-1&key=ccb91f29d6744675&client_code=ahl&league_id=4&callback=angular.callbacks._4"

FileUtils.mkdir_p("output")
response = HTTParty.get(url)
jsonp = response.body

json_start = jsonp.index("(")
json_end = jsonp.rindex(")")
json = jsonp[(json_start + 1)...json_end]
data = JSON.parse(json)

players = data[0]["sections"][0]["data"].map { |entry| entry["row"] }

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

File.write("output/reign_skaters.json", JSON.pretty_generate(cleaned))
puts "✅ Saved #{cleaned.size} skater stats"
