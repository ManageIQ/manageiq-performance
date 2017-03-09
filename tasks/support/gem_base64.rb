require "base64"
require "rubygems/package"

class GemBase64

  def self.gem_as_base64_string(gem_tar_io = self.gem_as_tar_io)
    Base64.encode64(gem_tar_io.read)
  end

  def self.gem_as_tar_io(gemspec = self.miqperf_gemspec)
    io = StringIO.new
    Gem::Package.new(io)
                .tap { |p| p.spec = gemspec }
                .build

    io.tap { |i| i.rewind }
  end

  def self.miqperf_gemspec
    filepath = File.expand_path "../../../manageiq-performance.gemspec", __FILE__
    Gem::Specification.load filepath
  end

  def self.find_gemspec_for gem
    gemspec = begin
                find_local_gemspec gem
              rescue Gem::LoadError
                Gem::Specification.new(gem)
              end

    unless File.exist? gemspec.cache_file
      # cache deleted or the gem never existed in the first place
      #
      # Much of this is taken from rubygems/remote_fetcher, specifically the
      # Gem::RemoteFetcher#download_to_cache method.
      gem_dependency  = create_dependency gemspec
      gemspec, source = Gem::SpecFetcher.fetcher
                                        .spec_for_dependency(gem_dependency)[0]
                                        .max_by { |(s,_)| s.version }

      Gem::RemoteFetcher.fetcher.download gemspec, source.uri.to_s, tmp_dir

      # This is set when the gemspec is created to the default location for the
      # gem cache, but we want it in a tmp dir that we set so we aren't adding
      # extra gems to the users gem dir without them knowing.
      gemspec.instance_variable_set(:@base_dir, tmp_dir)
      gemspec.instance_variable_set(:@cache_dir, nil)
      gemspec.instance_variable_set(:@cache_file, nil)
    end

    gemspec
  end

  private

  def self.tmp_dir
    @tmp_dir ||= Dir.mktmpdir "gembase64"
  end

  def self.create_dependency gemspec
    gem_requirement = Gem::Requirement.new gemspec.version
    Gem::Dependency.new gemspec.name, gem_requirement
  end

  def self.find_local_gemspec(gem)
    if defined?(Bundler)
      gemspec = ::Bundler.locked_gems.specs.detect { |spec| spec.name == gem } or raise Gem::LoadError
      gemspec.__materialize__
    else
      Gem::Specification.find_by_name(gem)
    end
  end
end
