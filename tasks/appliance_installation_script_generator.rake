require "erb"
require File.expand_path "../support/gem_base64", __FILE__

desc "Generate script for installing gem on an appliance"
task :generate_install_script do
  template_dir       = File.expand_path "../support/templates", __FILE__
  template_filename  = "appliance_installation_script.rb.erb"

  @gemspec           = GemBase64.gemspec
  @gem_base64_string = GemBase64.gem_as_base64_string
  @template          = File.read File.join(template_dir, template_filename)
  @output_filename   = "tmp/manageiq-performance-appliance-installation-script.rb"

  b = binding
  File.write @output_filename, ERB.new(@template, nil, "-").result(b)
end
