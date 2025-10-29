require "json"

skaters = JSON.parse(File.read("output/reign_skaters.json"))
goalies = JSON.parse(File.read("output/reign_goalies.json"))

merged = {
  skaters: skaters,
  goalies: goalies
}

File.write("output/reign_stats.json", JSON.pretty_generate(merged))
puts "✅ Merged stats written to output/reign_stats.json"
