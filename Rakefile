task :default => :new
require 'fileutils'
desc "Create new post"
task :new do
  puts "[-] Please input new post URL: "
  @url = STDIN.gets.chomp
  puts "[-] Please input post title: "
  @name = STDIN.gets.chomp
  puts "[-] Please input the categories: "
  @categories = STDIN.gets.chomp
  puts "[-] Please input the tags: "
  @tags = STDIN.gets.chomp
  @slug = "#{@url}"
  @slug = @slug.downcase.strip.gsub(' ', '-')
  @date = Time.now.strftime("%F")
  @post = "_posts/#{@date}-#{@slug}.md"
  if File.exist?(@post)
    abort("[!] Create new post failed, because the #{@post} is exists.")
  end
  FileUtils.touch(@post)
  open(@post, 'a') do |file|
    file.puts "---"
    file.puts "layout: post"
    file.puts "title: #{@name}"
    file.puts "date: #{Time.now}"
    file.puts "categories: #{@categories}"
    file.puts "tags: #{@tags}"
    file.puts "---"
  end
end
