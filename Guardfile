# A sample Guardfile
# More info at https://github.com/guard/guard#readme

STYLE_NAME='style.css'
TEMPLATE_NAME='index.html.liquid'

guard 'rake', :task => :html do
  watch(/.dot$/)
  watch(TEMPLATE_NAME)
  watch(STYLE_NAME) # not sure if this should be here
end
