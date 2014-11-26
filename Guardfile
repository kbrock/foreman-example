# A sample Guardfile
# More info at https://github.com/guard/guard#readme

DEFAULT_DOT=/\.dot$/ #'model.dot'
STYLE_NAME='style.css'
TEMPLATE_NAME='index.html.liquid'

guard 'rake', :task => 'default' do
  watch("Rakefile")
  watch(DEFAULT_DOT)
  watch(TEMPLATE_NAME)
  watch(STYLE_NAME)
end
