require 'erb'
require 'liquid'
require 'tilt'
require 'nokogiri'

class DotHelper
  attr_accessor :template_name

  def initialize(template_name)
    @template_name = template_name
  end

  @@template = nil
  def dot2svg(target, source)
    #sh "pandoc -o #{t.name} #{t.source}"
    puts `dot -Tsvg #{source} -o #{target}`
    puts "#{source} -> #{target}"
  end

  # TODO: use nokogiri?
  def strip_version(body)
    # remove xml version from the svg file
    body.gsub!(/^<\?.*\?>\n/,'')
    # remove DOCTYPE
    body.gsub!(/<!DOC[^>]*>\n/,'')
    body
  end

  def dom(source)
    Nokogiri::XML.parse(strip_version(File.read(source)))
  end

  def embed_images(body)
  end

  def extractTitle(doc)
    doc.css("title").first.content()
  end

  def svg2html(target, source)
    doc = dom(source)
    title = extractTitle(doc)
    embed_images(doc)
    body = doc.to_xml

    index_contents = template(true).render binding, title: title, body: body
    File.write(target, index_contents)
    puts "#{source} -> #{target}"
  end

  # load the template for this file
  def template(force = false)
    if (@@template.nil? || force)
      @@template = Tilt.new(template_name)
    else
      @@template
    end
  end
end
