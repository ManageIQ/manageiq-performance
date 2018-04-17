require "erb"
require File.expand_path "../support/gem_base64", __FILE__

SCRIPT_FILENAME = "tmp/manageiq-performance-appliance-installation-script.rb"

CLEAN.include SCRIPT_FILENAME

# clobber any renamed generated scripts that might have been renamed
CLOBBER.include "tmp/*_script.rb"

desc "Generate script for installing gem on an appliance"
task :generate_install_script do
  template_dir       = File.expand_path "../support/templates", __FILE__
  template_filename  = "appliance_installation_script.rb.erb"

  @gemspec           = GemBase64.miqperf_gemspec
  @gem_base64_string = GemBase64.gem_as_base64_string
  @template          = File.read File.join(template_dir, template_filename)
  @output_filename   = SCRIPT_FILENAME

  b = binding
  File.write @output_filename, ERB.new(@template, nil, "-").result(b)
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
