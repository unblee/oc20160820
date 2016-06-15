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
    utf8_file_name = convert_utf16to8(raw_file_name)
    convert2csv(utf8_file_name)
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

  def convert_utf16to8(raw_file_name)
    utf8_file_name = raw_file_name.sub(".txt", ".utf8.txt")
    return utf8_file_name if File.exists?(utf8_file_name)
    open(utf8_file_name, "ab") do |outfile|
      buf = open(raw_file_name, "rb").read
      buf.encode!(Encoding::UTF_8, Encoding::UTF_16, invalid: :replace, undef: :replace, replace: "*")
      buf.each_line do |line|
        next line if /^!/ =~ line
        outfile.puts(line)
      end
    end
    utf8_file_name
  end

  def convert2csv(utf8_file_name)
    dic_file_name = utf8_file_name.sub(".utf8.txt", ".csv")
    return dic_file_name if File.exists?(dic_file_name)
    open(dic_file_name, "ab") do |outfile|
      open(utf8_file_name, "rb:UTF-8") do |utf8_file|
        buf = utf8_file.read
        buf.each_line do |line|
          word = line.split(/\t/)
          content_arr = [word[1],"0","0",word_cost(word[1]),"名詞","固有名詞","*","*","*","*",word[1],word[0],word[0]]
          content = content_arr.join(",")
          outfile.puts(content)
        end
      end
    end
  end

  def word_cost(word)
    max = -36000.0
    val = -400.0 * (word.length ** 1.5)
    max = val if max <= val
    max
  end

  main

end
