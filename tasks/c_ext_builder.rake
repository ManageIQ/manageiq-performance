require File.expand_path "../support/gem_base64", __FILE__

TMP_C_EXT_GEMS_DIR = Pathname.new "tmp/installer_script_gems"

# For our purposes, this is just getting the currently installed ruby version,
# and the distro platform from the `rbconfig.rb` path.  Normally this would
# handled multiple ruby dirs, but since this is a system ruby in this
# container, that isn't needed.
RAKE_COMPILER_CONFIG_SETUP_RB_SCRIPT = <<-RC_SETUP_RB.lines.map(&:strip).join(' ')
  require 'fileutils';
  require 'pathname';
  require 'yaml';

  rake_compiler_config = Pathname.new(Dir.home).join '.rake-compiler', 'config.yml';
  FileUtils.mkdir_p rake_compiler_config.dirname;

  rbs = {};
  Dir['/usr/local/lib/ruby/**/rbconfig.rb'].each { |rbcf|
    p = rbcf.match(/\\d\\.\\d\\.\\d\\/([-\\w]+)\\/rbconfig/)[1];
    rbs['rbconfig-%s-%s' % [p,RUBY_VERSION]] = rbcf;
  };
  File.write rake_compiler_config, rbs.to_yaml;
RC_SETUP_RB

RAKE_COMPILER_DOCK_BASE_SETUP = <<-BASE_SETUP.lines.map(&:strip).join(" && ")
  gem install rake-compiler --no-ri --no-rdoc
  ruby -e "#{RAKE_COMPILER_CONFIG_SETUP_RB_SCRIPT}"
BASE_SETUP

CLEAN.include TMP_C_EXT_GEMS_DIR.to_s

task :build_c_ext_gem, [:gem] => [:create_c_ext_rakefile] do |t, args|
  gem_to_build = args[:gem]
  raise "You must include a c ext gem to build..." unless gem_to_build

  build_file = ext_build_for gem_to_build

  # Make all of the next section a internally created `file` rake rule so that
  # we only generate this if it doesn't already exist.
  file build_file do
    rake_compiler_dock_setup
    unpackaged_gem = TMP_C_EXT_GEMS_DIR.join(gem_to_build)

    rake_compiler_dock_cmd = <<-CMD.lines.map(&:strip).join(" && ")
      cd #{unpackaged_gem}
      rake cross native gem
    CMD
    rake_compiler_dock_cmd.prepend "; "
    rake_compiler_dock_cmd.prepend RAKE_COMPILER_DOCK_BASE_SETUP

    RakeCompilerDock.sh rake_compiler_dock_cmd, :check_docker => false,
                                                :runas => false,
                                                :sigfw => false
  end

  Rake::Task[build_file].invoke
end

# Build a Rakefile specific to building the unpacked_gem.
#
# Handles specfiles using `git ls-files` in them since they will not function
# properly in the docker container
#
# FIXME:  I think rubygems will put a gemspec in cache directory or something
# that properly has the files from the .gem tarball without the `git ls-files`
# non-sense, but I will have to determine where this is located.  This
# functions for the time being, but a bit of a hack... removing the gemspec
# cleaning stuff would be much better.
#
# FIXME Update: Found it... but it turns out that is only a half the solution
# wanted...  probably won't get much better then what is here...
task :create_c_ext_rakefile, [:gem] => :unpack_gem do |t, args|
  gem_name = args[:gem]
  raise "You must include a c ext gem to build..." unless gem_name

  # additional options for the Rake::ExtensionTask.  Gem specific.
  if @c_ext_gem_ext_opts and @c_ext_gem_ext_opts[gem_name]
    justify = [14, @c_ext_gem_ext_opts[gem_name].keys.map(&:length).max].max
    ext_opts_string = ""
    @c_ext_gem_ext_opts[gem_name].each do |opt, value|
      ext_opts_string << "ext.#{opt.to_s.ljust(justify)} = #{value.inspect}\n"
    end
  end

  gem_rakefile = TMP_C_EXT_GEMS_DIR.join(gem_name, "Rakefile")

  File.open gem_rakefile, "w" do |rakefile|
    rakefile.write <<-RAKEFILE.gsub(/^ {8}/, '')
      # For all of those folks who swear by `git ls-files` to define your
      # files in a gemspec file... this is why it is a PITA...

      gemspec = Gem::Specification::load("#{gem_name}.gemspec.safe")

      # Make sure the `gemspec.files` is fully populated, and only add files
      # from the `gemspec.require_paths`.
      extra_files   = Dir[*gemspec.require_paths.map {|p| "%s/**/*" % p }]
                         .reject {|f| File.directory?(f) }
      gemspec.files = gemspec.files | extra_files

      # Make sure we have a extension lib properly configured.  Fallback to the
      # original gemspec if the .safe version didn't include it right...
      extension_dir   = (gemspec.extensions || []).empty? ? nil : gemspec.extensions
      extension_dir ||= Dir["ext/**/extconf.rb"]
      extension_dir   = File.dirname(extension_dir.first)

      require 'rake/extensiontask'

      Rake::ExtensionTask.new "#{gem_name}", gemspec do |ext|
        ext.ext_dir        = extension_dir
        ext.cross_compile  = true
        ext.cross_platform = %w[x86_64-linux]
        #{ext_opts_string}
      end
    RAKEFILE
  end
end

# Fetch a .gem (from local cache, or from rubygems), and then unpack it in a
# tmp directory to have it's c-extension built
task :unpack_gem, [:gem] do |t, args|
  gem_to_unpack = args[:gem]
  raise "You must include a gem to unpack..." unless gem_to_unpack

  packaged_gem      = TMP_C_EXT_GEMS_DIR.join("#{gem_to_unpack}.gem")
  unpackaged_gem    = TMP_C_EXT_GEMS_DIR.join(gem_to_unpack)
  gemspec           = GemBase64.find_gemspec_for gem_to_unpack
  safe_gemspec_file = unpackaged_gem.join("#{gem_to_unpack}.gemspec.safe")

  file packaged_gem do
    mkdir_p TMP_C_EXT_GEMS_DIR
    cp gemspec.cache_file, packaged_gem
  end

  directory unpackaged_gem => packaged_gem do
    pkg = Gem::Package.new packaged_gem.to_s
    pkg.extract_files unpackaged_gem
  end

  # Ugh... I really wish this would have worked better...
  #
  # Basically, this writes a gemspec file to the gem that can be loaded
  # regardless of what was used to generate it (avoids trying to use a .gemspec
  # file that might have something like `git ls-files` in it, since that won't
  # work properly.
  #
  # This also should handle gems that embed their gemspecs in their Rakefile
  # instead of a .gemspec file in the root (also annoying...)
  file safe_gemspec_file => unpackaged_gem do
    File.write safe_gemspec_file, gemspec.to_ruby_for_cache
  end

  # the 'safe_gemspec' file task is used to chain triggering the other file
  # tasks, and they will only run if they are needed
  Rake::Task[safe_gemspec_file].invoke
end

namespace :build_c_ext_gem do
  desc "Debug a build by opening a interactive shell in the docker container"
  task :debug, [:gem] => [:create_c_ext_rakefile] do |t, args|
    rake_compiler_dock_setup

    puts
    puts "-------------------------------"
    puts
    puts "Starting debugging container..."
    puts
    puts "Since this is a new container, you will have to most likely run the"
    puts "following before running and debugging `rake cross native gem`."
    puts
    puts "$ #{RAKE_COMPILER_DOCK_BASE_SETUP}"
    puts "$ cd #{TMP_C_EXT_GEMS_DIR.join(args[:gem])}"
    puts

    # Pulled from the `bin/rake-compiler-dock` executable
    RakeCompilerDock.exec 'bash', {:sigfw => false, :runas => false}
  end
end

desc "Remove the docker-machine instance for rake-compiler-dock"
task :delete_docker_machine do
  sh "docker-machine rm -y --force #{ENV["MACHINE_NAME"] || 'rake-compiler-dock'}"
end
# Add the above task as a prerequisite for `rake clobber`
Rake::Task[:clobber].enhance [:delete_docker_machine]

# Configures the docker environment consistently prior to debugging or running
# a build
def rake_compiler_dock_setup
  ENV["RAKE_COMPILER_DOCK_IMAGE"] ||= "manageiq/ruby"
  machine_name                      = ENV["MACHINE_NAME"] || nil

  require 'rake_compiler_dock'

  # Allows us to customize what the docker-machine name is, incase someone has
  # it running currently
  docker = RakeCompilerDock::DockerCheck.new(*[$stderr, Dir.pwd, machine_name].compact)
  docker.ok?
end

def ext_build_for gem
  gemspec      = GemBase64.find_gemspec_for gem
  dot_gem_file = "#{gemspec.name}-#{gemspec.version}-x86_64-linux.gem"
  TMP_C_EXT_GEMS_DIR.join(gemspec.name, "pkg", dot_gem_file)
end
