require "fileutils"
require "open-uri"
require "zip"
require "stackprof"

git_rev = `git rev-parse --short HEAD`
git_rev.chomp!
StackProf.run(mode: :cpu, raw: true, out: "stackprof/#{git_rev}") do

  def main
    zip_file_name = get_file("http://web-apps.nbookmark.com/hatena-dic/hatena_msime_nocomment.zip")
    raw_file_name = unzip_file(zip_file_name)
    convert2csv(raw_file_name)
  end

  def get_file(url)
    dir_name = "./dic"
    FileUtils.mkdir_p(dir_name) unless File.directory?(dir_name)
    file_name = File.basename(url)
    zip_file_name = File.join(dir_name, file_name)
    unless File.exists?(zip_file_name)
      open(zip_file_name, "wb") do |output|
        open(url) do |data|
          output.write(data.read)
        end
      end
    end
    zip_file_name
  end

  def unzip_file(zip_file_name)
    unzip_file_name = zip_file_name.sub(".zip", ".txt")
    return unzip_file_name if File.exists?(unzip_file_name)
    Zip::File.open(zip_file_name) do |zf|
      zf.each do |entry|
        entry.extract(unzip_file_name)
      end
    end
    unzip_file_name
  end

  def convert2csv(raw_file_name)
    dic_file_name = raw_file_name.sub(".txt", ".csv")
    return dic_file_name if File.exists?(dic_file_name)
    outfile = open(dic_file_name, "ab")
    buf = open(raw_file_name, "rb:UTF-16:UTF-8").read
    buf.sub!("!Microsoft IME Dictionary Tool\n", "")
    buf.each_line do |line|
      word = line.split(/\t/)
      content = word[1] << "0,0" << word_cost(word[1]).to_s << "名詞,固有名詞,*,*,*,*" << word[1] << word[0] << word[0]
      outfile.puts(content)
    end
    outfile.close
  end

  def word_cost(word)
    max = -36000.0
    val = -400.0 * (word.length ** 1.5)
    max = val if max <= val
    max
  end

  main

end
