# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

# Wire module
module Wire
  # SpecWriter is able to create a directory
  # structure according to basic serverspec
  # needs and fill in the templates
  class SpecWriter
    # create SpecWriter in +target_dir+ directory
    # with given +spec_contents+
    def initialize(target_dir, spec_contents)
      @target_dir = target_dir
      @spec_contents = spec_contents
    end

    # writes spec to disk
    def write
      ensure_directory_structure
      ensure_files
    end

    # make sure that we have a rspec-conformant dir structure
    def ensure_directory_structure
      ensure_directory @target_dir
      ensure_directory File.join(@target_dir, 'spec')
      ensure_directory File.join(@target_dir, 'spec', 'localhost')
    end

    # writes erb +template+ to open +file+ object
    def write_template(template, file)
      erb = ERB.new(template, nil, '%')
      file.puts(erb.result(binding))
    end

    # ensures that all serverspec skeleton files such as
    # Rakefile, spec_helper etc. exist
    # Then writes the models specification files into the
    # skeleton
    def ensure_files
      rakefile_name = File.join(@target_dir, 'Rakefile')
      file?(rakefile_name) || File.open(rakefile_name, 'w') do |file|
        write_template(SpecTemplates.template_rakefile, file)
      end

      spechelper_name = File.join(@target_dir, 'spec', 'spec_helper.rb')
      file?(spechelper_name) || File.open(spechelper_name, 'w') do |file|
        write_template(SpecTemplates.template_spec_helper, file)
      end

      specfile_name = File.join(@target_dir, 'spec', 'localhost', 'wire_spec.rb')
      File.open(specfile_name, 'w') do |file|
        template = <<ERB
require 'spec_helper.rb'

# begin of generated specs

<%= @spec_contents.join('\n') %>

# end of spec file
ERB
        write_template(template, file)
      end
    end

    private

    # make sure that +target_dir+ exists
    def ensure_directory(target_dir)
      return if File.exist?(target_dir)
      begin
        FileUtils.mkdir_p(target_dir)
      rescue => excpt
        $log.error "ERROR: Unable to create #{target_dir}: #{excpt}"
      end
    end

    # checks if +target_file+ exists
    def file?(target_file)
      File.exist?(target_file) && File.file?(target_file)
    end
  end
end
