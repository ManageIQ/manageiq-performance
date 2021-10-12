require "tasks/support/gem_base64"
require "manageiq_performance/version"
require "fileutils"
require "timecop"
require "rspec/version"

def build_gem file
  pkg_dir = File.dirname file
  FileUtils.mkdir_p pkg_dir
  FileUtils.touch file
  file_obj = File.new(file, "w+")

  Gem.load_yaml

  gem_pkg = Gem::Package.new(file_obj).tap { |p| p.spec = GemBase64.miqperf_gemspec }
  gem_pkg.setup_signer
  gem_pkg.instance_variable_get(:@gem).with_write_io do |gem_io|
    Gem::Package::TarWriter.new gem_io do |gem|
      gem_pkg.add_metadata  gem
      gem_pkg.add_contents  gem
      gem_pkg.add_checksums gem
    end
  end
end

def decode64 string
  # Convert from a base64 string to a tar ball file contents
  StringIO.new Base64.decode64(string)
end

def untar io
  # Un tar the specific file for comparison
  extracted_contents = {}
  gem_tar = Gem::Package::TarReader.new(io)
  gem_tar.each do |entry|
    case entry.full_name
    when "metadata.gz", "checksums.yml.gz"
      Zlib::GzipReader.wrap entry do |gzio|
        extracted_contents[entry.full_name] = gzio.read
      end
    when "data.tar.gz"
      data_contents = extracted_contents["data.tar.gz"] = {}
      Zlib::GzipReader.wrap entry do |gzio|
        Gem::Package::TarReader.new(gzio).each do |dot_gem_file|
          data_contents[dot_gem_file.full_name] = dot_gem_file.read
        end
      end
    end
  end

  extracted_contents
end

def decode_and_untar gem_string
  untar decode64(gem_string)
end

describe GemBase64 do
  let(:version)   { Gem::Version.new(ManageIQPerformance::VERSION) }
  let(:spec_dir)  { File.expand_path "../../..", __FILE__ }
  let(:spec_tmp)  { "#{spec_dir}/tmp" }
  let(:pkg_dir)   { "#{spec_tmp}/pkg" }
  let(:gem_file)  { "#{pkg_dir}/manageiq_performance-#{version.to_s}.gem" }
  let(:time_lock) { Time.now }

  around(:each) do |example|
    Gem::DefaultUserInteraction.use_ui(Gem::SilentUI.new) do
      Timecop.freeze(time_lock) { build_gem gem_file }
      example.run
    end
    FileUtils.rm_rf spec_tmp
  end

  describe "::miqperf_gemspec" do
    it "reads the .gemspec file and returns a Gem::Specification instance" do
      expect(GemBase64.miqperf_gemspec.name).to    eq "manageiq-performance"
      expect(GemBase64.miqperf_gemspec.version).to eq version
    end
  end

  describe "::gem_as_tar_io" do
    it "returns an io object of the .gem (tar) contents" do
      result = Timecop.freeze(time_lock) { GemBase64.gem_as_tar_io }
      expect(result.read).to eq File.read(gem_file)
    end
  end

  describe "::gem_as_base64_string" do
    it "returns a base64 string version of the .gem that recompiles back correctly" do
      bin_file         = File.expand_path("../../../../bin/miqperf", __FILE__)
      expected_content = File.read bin_file
      base64_content   = Timecop.freeze(time_lock) { GemBase64.gem_as_base64_string }
      actual_content   = decode_and_untar base64_content

      expect(actual_content["data.tar.gz"]["bin/miqperf"]).to eq expected_content
    end
  end

  describe "::find_gemspec_for" do
    context "for a gem in the bundle" do
      it "returns the .gemspec object for the gem" do
        gem     = "rspec"
        version = Gem::Version.new RSpec::Version::STRING
        result  = GemBase64.find_gemspec_for gem

        expect(result.name).to    eq gem
        expect(result.version).to eq version
      end
    end

    context "for a gem not in the bundle" do
      after { FileUtils.rm_rf GemBase64.tmp_dir }

      it "returns the .gemspec object for the gem" do
        gem            = "nyan-cat-formatter"
        version        = Gem::Version.new "0.12"
        result         = GemBase64.find_gemspec_for gem
        cache_file_loc = File.join GemBase64.tmp_dir, "cache", "#{gem}-0.12.0.gem"

        expect(result.name).to       eq gem
        expect(result.version).to    eq version
        expect(result.cache_file).to eq cache_file_loc
      end
    end
  end
end
