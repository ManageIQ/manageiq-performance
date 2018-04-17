require "erb"
require File.expand_path "../support/gem_base64", __FILE__

SCRIPT_FILENAME = "tmp/manageiq-performance-appliance-installation-script.rb"

CLEAN.include SCRIPT_FILENAME

# clobber any renamed generated scripts that might have been renamed
CLOBBER.include "tmp/*_script.rb"


desc "Generate script for installing gem on an appliance"
task :generate_install_script do
  require File.expand_path "../../lib/manageiq_performance/utils/template_helper", __FILE__
  include TemplateHelper

  def template_dir
    @template_dir ||= File.expand_path "../support/templates", __FILE__
  end

  template_dir       = File.expand_path "../support/templates", __FILE__
  template_filename  = "appliance_installation_script.rb.erb"

  @gemspec           = GemBase64.miqperf_gemspec
  @gem_base64_string = GemBase64.gem_as_base64_string
  @template          = File.read File.join(template_dir, template_filename)
  @output_filename   = SCRIPT_FILENAME

  b = binding
  File.write @output_filename, ERB.new(@template, nil, "-").result(b)
  puts "Generated #{@output_filename}"
end

desc "Add stackprof to install script (use with generate_install_script task)"
task :include_stackprof do
  @c_ext_gem_ext_opts            ||= {}
  @c_ext_gem_ext_opts['stackprof'] = { :lib_dir => 'lib/stackprof' }

  # Build the gem for our target if it doesn't already exist
  Rake::Task[:build_c_ext_gem].invoke "stackprof"

  @stackprof_gemspec   = GemBase64.find_gemspec_for "stackprof"
  stackprof_gem_tar_io = File.new ext_build_for("stackprof"), "r"

  @stackprof_gem_base64_string = GemBase64.gem_as_base64_string stackprof_gem_tar_io
end


desc <<-DESC
Include a single gem, excluding manageiq-performance

(use with generate_install_script)

Useful when not trying to install `manageiq-performance`, but another gem on an
existing appliance.

Example:

$ rake solo_gem[vcr] generate_install_script
$ rake solo_gem[path/to/my_gem/my_gem.gemspec] generate_install_script

DESC
task :solo_gem, [:gem] do |t, args|
  @solo_gem = true

  new_gem = args[:gem]
  raise "You must include a gem to add..." unless new_gem

  add_gem_entry new_gem
end


desc <<-DESC
Include a single c gem, excluding manageiq-performance

(use with generate_install_script)

Useful when not trying to install `manageiq-performance`, but another gem on an
existing appliance.

Example:

$ rake solo_c_gem[stackprof] generate_install_script
$ rake solo_c_gem[path/to/my_gem/my_gem.gemspec] generate_install_script

DESC
task :solo_c_gem, [:gem] do |t, args|
  @solo_gem = true

  new_gem = args[:gem]
  raise "You must include a gem to add..." unless new_gem

  add_gem_entry new_gem, :c_ext => true
end

desc "Alias for :solo_c_gem"
task :solo_c_ext_gem, [:gem] => :solo_c_gem


desc <<-DESC
Include a single, extra gem

(use with generate_install_script task)

Adds another gem to the installtion along side `manageiq-performance`.

Example:

$ rake extra_gem[vcr] generate_install_script
$ rake extra_gem[path/to/my_gem/my_gem.gemspec] generate_install_script

This can also be used along side the `:solo_gem` task if you wish to install
multiple gems without manageiq-performance:

$ rake solo_gem[vcr] extra_gem[thor] generate_install_script

DESC
task :extra_gem, [:gem] do |t, args|
  new_gem = args[:gem]
  raise "You must include a gem to add..." unless new_gem

  add_gem_entry new_gem
end


desc <<-DESC
Include a single, extra c-ext gem

(use with generate_install_script task)

Adds another gem to the installtion along side `manageiq-performance`, with a
pre-compiled c-ext.

Example:

$ rake extra_c_gem[stackprof] generate_install_script
$ rake extra_c_gem[path/to/my_gem/my_gem.gemspec] generate_install_script

This can also be used along side the `:solo_gem`/`:solo_c_gem` task if you wish
to install multiple gems without manageiq-performance:

$ rake solo_gem[vcr] extra_c_gem[stackprof] generate_install_script

DESC
task :extra_c_gem, [:gem] do |t, args|
  new_gem = args[:gem]
  raise "You must include a gem to add..." unless new_gem

  add_gem_entry new_gem, :c_ext => true
end

desc "Alias for :extra_c_gem"
task :extra_c_ext_gem, [:gem] => :extra_c_gem

def add_gem_entry(new_gem, opts = {})
  Rake::Task[:build_c_ext_gem].invoke new_gem if opts[:c_ext]

  @other_gems ||= []
  @other_gems << {}.tap {|new_gem_entry|
    path = new_gem if File.exist? new_gem
    gemspec = GemBase64.find_gemspec_for new_gem, path

    new_gem_entry[:gemspec]  = gemspec
    new_gem_entry[:name]     = gemspec.name
    new_gem_entry[:env_name] = gemspec.name.upcase.gsub "-", "_"

    if path
      new_gem_tar_io = GemBase64.gem_as_tar_io gemspec
    elsif opts[:c_ext]
      new_gem_tar_io = File.new ext_build_for(new_gem), "r"
      new_gem_entry[:platform] = "x86_64-linux"
    else
      new_gem_tar_io = File.new gemspec.cache_file, "r"
    end
    new_gem_base64_string = GemBase64.gem_as_base64_string new_gem_tar_io
    new_gem_entry[:gem_base64_string] = new_gem_base64_string
  }
end
