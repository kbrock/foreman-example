require 'highline/import'
require 'highline/system_extensions'
include HighLine::SystemExtensions

# stolen from appliance_console/prompts.rb
module HighlineHelper
  def default_to_index(default, options)
    return options.size == 1 ? "1" : nil if default.nil?
    default_index = if options.is_a?(Hash)
                      options.values.index(default) || options.keys.index(default)
                    else
                      options.index(default)
                    end
    default_index ? (default_index.to_i + 1).to_s : default.to_s
  end

  def ask_with_menu(prompt, options, default = nil)
    say("\n#{prompt}\n\n")

    default = default_to_index(default, options)
    selection = nil
    choose do |menu|
      menu.default      = default
      menu.index        = :number
      menu.index_suffix = ") "
      menu.prompt       = "\nChoose the #{prompt.downcase}:#{" |#{default}|" if default} "
      options.each { |o, v| menu.choice(o) { |c| selection = v || c } }
      yield menu if block_given?
    end
    selection
  end
end
