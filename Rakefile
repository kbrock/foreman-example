require 'erb'
require 'liquid'
require 'tilt'
require 'nokogiri'

STYLE_NAME='style.css'
TEMPLATE_NAME='index.html.liquid'

task :default => :html
task :html => 'model.html'

class DotHelper
  @@template = nil
  def self.dot2svg(target, source)
    #sh "pandoc -o #{t.name} #{t.source}"
    puts `dot -Tsvg #{source} -o #{target}`
    puts "#{source} -> #{target}"
  end

  def self.svg2html(target, source)
    body = File.read(source)
    title = Nokogiri::XML.parse(File.read(source)).css("title").first.content()

    # remove xml version from the svg file
    body.gsub!(/^<\?.*\?>\n/,'')
    # remove DOCTYPE
    body.gsub!(/<!DOC[^>]*>\n/,'')

    index_contents = template(true).render binding, title: title, body: body
    File.write(target, index_contents)
    puts "#{source} -> #{target}"
  end

  # load the template for this file
  def self.template(force = false)
    if (@@template.nil? || force)
      @@template = Tilt.new(TEMPLATE_NAME)
    else
      @@template
    end
  end

  def self.reload_browser
    puts "refreshing browser"
    `osascript -e 'tell application "Google Chrome" to tell the active tab of its first window to reload'`
  end
end

rule ".svg" => ".dot" do |t|
  DotHelper.dot2svg(t.name, t.source)
end

rule '.html' => [".svg", STYLE_NAME, TEMPLATE_NAME] do |t|
  DotHelper.svg2html(t.name, t.source)
  DotHelper.reload_browser
end
