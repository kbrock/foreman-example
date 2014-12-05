# A sample Guardfile
# More info at https://github.com/guard/guard#readme

STYLE_NAME='style.css'
TEMPLATE_NAME='index.html.liquid'

Dir.glob("*.dot").each do |dot|
  dot = File.expand_path(dot)
  guard 'rake', :task => dot.sub(/\.dot$/, ".html") do
    watch(/#{dot}/)
    watch(TEMPLATE_NAME)
    watch(STYLE_NAME) # not sure if this should be here
  end
end
