require "base64"
require "rubygems/package"

class GemBase64

  def self.gem_as_base64_string
    Base64.encode64(gem_as_tar_io.read)
  end

  def self.gem_as_tar_io
    io = StringIO.new
    Gem::Package.new(io)
                .tap { |p| p.spec = gemspec }
                .build

    io.tap { |i| i.rewind }
  end

  def self.gemspec
    filepath = File.expand_path "../../../manageiq-performance.gemspec", __FILE__
    Gem::Specification.load filepath
  end
end
