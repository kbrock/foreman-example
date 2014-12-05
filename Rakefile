
# Rakefile to build dot files
# dependencies:
# mac 
# graphviz to convert dot files to svg

require_relative 'dot_helper'

STYLE_NAME='style.css'
TEMPLATE_NAME='index.html.liquid'

task :default => 'model.html'

task :refresh_browser do
  puts "refreshing browser"
  # NOTE: it only refreshes the currently active tab
  # more work can be done to find the approperiate tab
  `osascript -e 'tell application "Google Chrome" to tell the active tab of its first window to reload'` 
end

rule ".svg" => ".dot" do |t|
  DotHelper.new(TEMPLATE_NAME).dot2svg(t.name, t.source)
end

rule '.html' => [".svg", STYLE_NAME, TEMPLATE_NAME] do |t|
  DotHelper.new(TEMPLATE_NAME).svg2html(t.name, t.source)
  Rake::Task["refresh_browser"].invoke
end
