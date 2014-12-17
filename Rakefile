require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "dothtml/dot_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

Dothtml::DotTask.new do |t|
  t.d3js      = "d3.v3.js"
  t.style     = "style.css"
end

task :default => :html

task :html do
  Dir.glob("*.dot").each do |f|
    Rake::Task[f.sub(/\.dot$/, '.html')].invoke
  end
end
