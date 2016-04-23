require 'restclient'
require 'ostruct'
require 'date'
require 'open-uri'

def days_to_seconds(days)
  return days * 24 * 60 * 60
end

CACHE_DURATION = days_to_seconds(3)

def is_integer?(string)
  /\A[-+]?\d+\z/ === string
end

def print_text(s)
  puts s
end

def error_log(s)
  File.open("error_log.txt", File::WRONLY | File::CREAT | File::APPEND) do |f|
    f.flock(File::LOCK_EX)
    f.puts("#{DateTime.now} - #{s}")
    f.flush
  end
end

def detailed_log(s)
  File.open("detailed_log.txt", File::WRONLY | File::CREAT | File::APPEND) do |f|
    f.flock(File::LOCK_EX)
    f.puts("#{DateTime.now} - #{s}")
    f.flush
  end
end

def read_entry_from_cache(f)
  lines = []
  11.times do
    if not f.eof?
      lines.push f.gets.chomp
    else
      return nil
    end
  end
  return lines
end

def remove_expired_cache
  keep_entries = []
  begin
    File.open("cache.txt", "r") do |f|
      lines = read_entry_from_cache(f)
      while lines
        if ((DateTime.now - DateTime.parse(lines[0])) * 24 * 60 * 60).to_i < CACHE_DURATION
          keep_entries.push lines
        end
        lines = read_entry_from_cache(f)
      end
    end
  rescue StandardError => e
    error_log("Could not read in remove_expired_cache, Error: #{e.to_s}")
  end
  
  File.open("cache.txt", "w") do |f|
    keep_entries.each do |entry|
      entry.each do |line|
        f.puts(line)
      end
    end
    f.flush
  end
end

def get_from_cache(name, year)
  begin
    File.open("cache.txt", "r") do |f|
      lines = read_entry_from_cache(f)
      while lines
        if lines[1] == name and lines[2] == year
          return OpenStruct.new(title: lines[3],
                                year: lines[4],
                                rating: lines[5].to_f,
                                votes: lines[6], 
                                genre: lines[7],
                                plot: lines[8],
                                runtime: Integer(lines[9]))
        end
        lines = read_entry_from_cache(f)
      end
      return nil
    end
  rescue StandardError => e
    error_log("Could not get_from_cache cache, Error: #{e.to_s}")
    return nil
  end
end

def download_and_save_poster(name, year, url)
  begin
    if not File.exist?("poster/#{name}-#{year}.jpg")
      open("poster/#{name}-#{year}.jpg", "wb") do |file|
        file << open(url).read
      end
    end
  rescue StandardError => e
    error_log("Could not download poster: #{url}, Error: #{e.to_s}")
  end
end

def add_to_cache(name, year, data)
  download_and_save_poster(name, year, data.poster)
  File.open("cache.txt", "a+") do |f|
    f.puts(DateTime.now)
    f.puts(name)
    f.puts(year)
    f.puts(data.title)
    f.puts(data.year)
    f.puts(data.rating)
    f.puts(data.votes)
    f.puts(data.genre)
    f.puts(data.plot)
    f.puts(data.runtime)
    f.puts("")
    f.flush
  end
end

def get_data_for(name, year)
  cached = get_from_cache(name, year)
  if cached
    return cached
  end
  jdata = JSON.parse(RestClient.get "http://www.omdbapi.com/?t=#{name}&y=#{year}&plot=short&r=json")
  data = OpenStruct.new(title: jdata["Title"],
                        year: jdata["Year"],
                        rating: jdata["imdbRating"].to_f,
                        votes: jdata["imdbVotes"], 
                        genre: jdata["Genre"],
                        plot: jdata["Plot"],
                        runtime: Integer(jdata["Runtime"].split.first),
                        poster: jdata["Poster"])
  add_to_cache(name, year, data)
  return data
end

def is_name_blacklisted?(name)
  blacklisted_names = ["1080p", #TODO, config with these
                       "BluRay",
                       "FGT",
                       "DTS",
                       "LIMITED",
                       "DTS",
                       "EXTENDED",
                       "REMASTERED",
                       "REPACK",
                       "WEB-DL",
                       "DD5",
                       "264",
                       "720p",
                       "RARBG",
                       "AC3",
                       "XviD",
                       "anoX",
                       "BRRip",
                       "HDRip",
                       "DC",
                       "iNTERNAL",
                       "CRF",
                       "Directors",
                       "Cut"]
                       
  blacklists = blacklisted_names.select{|blacklist| name.include?(blacklist)}
  if blacklists.empty?
    return false
  end
  return true
end

def do_folder(folder)
  if folder.start_with?("Old/") # TODO config with list of accepted subfolders
    folder = folder[4..-1]
  end
  if folder.split('/').length > 1
    return false
  end
  folder = folder.sub('.5.1', '')
  folder = folder.sub('.DD5.1', '')
  folder = folder.sub('.H.264', '')
  if folder.empty?
    return false
  end
  
  begin
    names = folder.split('.').select {|s| not is_name_blacklisted?(s)}
    search_q = ""
    year = ""
    while not names.empty? do
      n = names.shift
      if is_integer?(n) and n.length == 4
        year = n
      else
        if not search_q.empty?
          search_q += "+"
        end
        search_q += n
      end
    end
    data = get_data_for(search_q, year)
    return data
  rescue StandardError => e
    print_text "Could not parse: #{folder}"
    error_log("Could not parse: #{folder}, Error: #{e.to_s}")
    return false
  end
end

def run(folders)
  fin_data = []
  folders.each do |folder| 
    data = do_folder(folder)
    if data
      fin_data.push data
    end
  end
  fin_data = fin_data.sort_by { |x| x.rating }
  print_text ""
  print_text ""
  print_text ""
  fin_data.each do |d|
    runtime_h = d.runtime / 60
    runtime_m = d.runtime - (60 * runtime_h)
    print_text "#{d.title} (#{d.year}) - #{d.rating} (#{d.votes}) - #{d.genre} - #{runtime_h}h #{runtime_m}m"
    print_text "#{d.plot}"
    print_text ""
  end
end

begin
  Dir.mkdir 'poster'
rescue StandardError => e
  error_log("Could not create poster folder, Error: #{e.to_s}")
end
remove_expired_cache()

path = ARGV[0].gsub('\\', '/')
folders = Dir.glob("#{path}/**/")
folders.map! do |folder|
  folder[path.length+1..-1]
end
run(folders)



