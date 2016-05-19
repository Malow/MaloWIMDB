def error_log(s)
  dir = Dir.getwd#(File.expand_path __FILE__).split('/')[0..-2].join('/')
  File.open("#{dir}/error_log.txt", File::WRONLY | File::CREAT | File::APPEND) do |f|
    f.flock(File::LOCK_EX)
    f.puts("#{DateTime.now} - #{s}")
    f.flush
  end
end

error_log("lol")
error_log(Dir.getwd)

error_log("ARGV: #{ARGV[0]}")
current_title = "12 Angry Men (1957) - 8.9"
current_votes = "431,964"
current_genre = "Crime, Drama"
current_runtime = "1h 36m"
current_plot = "A jury holdout attempts to prevent a miscarriage of justice by forcing his colleagues to reconsider the evidence."
current_poster = "poster/12+angry+men-1957.jpg"

Shoes.app(width: 1000, height: 900, title: "MaloWIMDB") {
  stack() {
    title "CurDir Below", stroke: "#000000", size: "x-large"
    begin
      title "Current dir: #{Dir.getwd}", stroke: "#000000", size: "x-large"
    rescue StandardError => e
      title "Error: #{e.to_s}", stroke: "#000000", size: "x-large"
      error_log("Error: #{e.to_s}")
    end
  }
  
  background "../bg.jpg"
  10.times do
    flow(margin: 10, width: 980) {  
      background "../bg-part.jpg"
      border "#111111", strokewidth: 3
      image(
        current_poster,
        width: 120,
        margin: 3
      )
      stack(margin: 0, width: 840) {
        title current_title, stroke: "#EEEEEE", size: "x-large"
        para strong("#{current_genre} - #{current_runtime} - #{current_votes} votes"), stroke: "#EEEEEE"
        para "#{current_plot}", stroke: "#EEEEEE"
      }
    }
  end
}
