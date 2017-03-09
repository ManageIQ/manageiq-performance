require "tasks/support/gem_base64"
require "manageiq_performance/version"
require "fileutils"
require "timecop"

def build_gem file
  pkg_dir = File.dirname file
  FileUtils.mkdir_p pkg_dir
  FileUtils.touch file
  file_obj = File.new(file, "w+")

  Gem::Package.new(file_obj)
              .tap{ |p| p.spec = GemBase64.miqperf_gemspec }
              .build
end

def decode_and_untar gem_string, pattern="*"
  # Convert from a base64 string to a tar ball file contents
  gem_io = StringIO.new Base64.decode64(gem_string)
  # Un tar the specific file for comparison
  extracted_contents = ""
  gem_tar = Gem::Package::TarReader.new(gem_io)
  gem_tar.each do |entry|
    next unless entry.full_name == 'data.tar.gz'

    Zlib::GzipReader.wrap entry do |gzio|
      Gem::Package::TarReader.new(gzio).each do |dot_gem_file|
        next unless File.fnmatch pattern, dot_gem_file.full_name, File::FNM_DOTMATCH
        extracted_contents = dot_gem_file.read
        # don't break here to avoid zlib warning
      end
    end

    break # ignore further entries (optimization)
  end

  extracted_contents
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
    it "returns a base65 string version of the .gem that recompiles back correctly" do
      bin_file         = File.expand_path("../../../../bin/miqperf", __FILE__)
      expected_content = File.read bin_file
      base64_content   = Timecop.freeze(time_lock) { GemBase64.gem_as_base64_string }
      actual_content   = decode_and_untar base64_content, "bin/miqperf"

      expect(actual_content).to eq expected_content
    end
  end
end
