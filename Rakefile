require "dothtml/dot_task"

Dothtml::DotTask.new do |t|
  t.d3js      = "d3js.v3.js"
end

task :default => :html

task :html do
  Dir.glob("*.dot").each do |f|
    Rake::Task[f.sub(/\.dot$/, '.html')].invoke
  end
end
