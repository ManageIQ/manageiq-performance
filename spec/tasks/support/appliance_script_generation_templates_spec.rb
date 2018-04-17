require "tasks/support/gem_base64"
require "manageiq_performance/utils/template_helper"
require "manageiq_performance/version"

class FakeTemplate
  include TemplateHelper

  def template_dir
    gem64 = GemBase64.method(:miqperf_gemspec).source_location[0]
    @template_dir ||= File.expand_path "../templates", gem64
  end
end

describe "appliance script templates" do
  subject { FakeTemplate.new }
  let(:random_gem_gemspec) {
    Gem::Specification.new do |spec|
      spec.name    = "foobar"
      spec.version = "0.1.0"
    end
  }

  describe "_gem_constants.rb.erb" do
    context "for the manageiq-performance gem" do
      let(:locals) {
        {
          :name     => "manageiq-performance",
          :env_name => "MIQPERF",
          :gemspec  => GemBase64.miqperf_gemspec
        }
      }

      it "renders the contants for MIQPERF" do
        expected = <<-TEMPLATE_OUTPUT.gsub(/^ */, '')
          MIQPERF_GEM_NAME         = "manageiq-performance"
          MIQPERF_GEM_VERSION      = "#{locals[:gemspec].version}"
          MIQPERF_FULL_GEM_NAME    = "\#{MIQPERF_GEM_NAME}-\#{MIQPERF_GEM_VERSION}"
          MIQPERF_INSTALL_LOCATION = "\#{GEM_INSTALL_DIR}/gems/\#{MIQPERF_FULL_GEM_NAME}"
        TEMPLATE_OUTPUT

        expect(subject.render_partial "gem_constants", locals).to eq expected
      end
    end

    context "for a random gem" do
      let(:locals) {
        {
          :name     => random_gem_gemspec.name,
          :env_name => "FOOBAR",
          :gemspec  => random_gem_gemspec
        }
      }

      it "renders the contants for FOOBAR" do
        expected = <<-TEMPLATE_OUTPUT.gsub(/^ */, '')
          FOOBAR_GEM_NAME         = "foobar"
          FOOBAR_GEM_VERSION      = "0.1.0"
          FOOBAR_FULL_GEM_NAME    = "\#{FOOBAR_GEM_NAME}-\#{FOOBAR_GEM_VERSION}"
          FOOBAR_INSTALL_LOCATION = "\#{GEM_INSTALL_DIR}/gems/\#{FOOBAR_FULL_GEM_NAME}"
        TEMPLATE_OUTPUT

        expect(subject.render_partial "gem_constants", locals).to eq expected
      end
    end

    context "for a random gem for a specific platform" do
      let(:locals) {
        {
          :name     => random_gem_gemspec.name,
          :env_name => "FOOBAR",
          :gemspec  => random_gem_gemspec,
          :platform => "x86_64-linux"
        }
      }

      it "renders the contants for FOOBAR with the platform appended to the install location" do
        expected = <<-TEMPLATE_OUTPUT.gsub(/^ */, '')
          FOOBAR_GEM_NAME         = "foobar"
          FOOBAR_GEM_VERSION      = "0.1.0"
          FOOBAR_FULL_GEM_NAME    = "\#{FOOBAR_GEM_NAME}-\#{FOOBAR_GEM_VERSION}"
          FOOBAR_INSTALL_LOCATION = "\#{GEM_INSTALL_DIR}/gems/\#{FOOBAR_FULL_GEM_NAME}-x86_64-linux"
        TEMPLATE_OUTPUT

        expect(subject.render_partial "gem_constants", locals).to eq expected
      end
    end
  end

  describe "_gem_base64_string.rb.erb" do
    let(:fake_base64_string) {
      <<-FAKE_BASE64_STRING.gsub(/^ */, "")
        bWV0YWRhdGEuZ3oAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAADAwMDA0NDQAMDAwMDAwMAAwMDAwMDAwADAwMDAwMDAyMjQ3
        ADEzMTQwMTU2MjQxADAxMzQ0MAAgMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB1c3RhcgAwMHdoZWVs
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAd2hlZWwAAAAAAAAAAAAAAAAA
        ...
      FAKE_BASE64_STRING
    }

    context "for the manageiq-performance gem" do
      let(:locals) {
        {
          :env_name          => "MIQPERF",
          :gem_base64_string => fake_base64_string
        }
      }

      it "renders the code for the manageiq_performance.gem as a base64 string" do
        expected = <<-TEMPLATE_OUTPUT.gsub(/^ */, '')
          MIQPERF_GEM_BUNDLE = <<-GEM_DATA
          bWV0YWRhdGEuZ3oAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
          AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
          AAAAAAAAAAAAADAwMDA0NDQAMDAwMDAwMAAwMDAwMDAwADAwMDAwMDAyMjQ3
          ADEzMTQwMTU2MjQxADAxMzQ0MAAgMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
          AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
          AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB1c3RhcgAwMHdoZWVs
          AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAd2hlZWwAAAAAAAAAAAAAAAAA
          ...
          GEM_DATA
        TEMPLATE_OUTPUT

        expect(subject.render_partial "gem_base64_string", locals).to eq expected
      end
    end

    context "for a random gem" do
      let(:locals) {
        {
          :env_name          => "FOOBAR",
          :gem_base64_string => fake_base64_string
        }
      }

      it "renders the code for the manageiq_performance.gem as a base64 string" do
        expected = <<-TEMPLATE_OUTPUT.gsub(/^ */, '')
          FOOBAR_GEM_BUNDLE = <<-GEM_DATA
          bWV0YWRhdGEuZ3oAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
          AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
          AAAAAAAAAAAAADAwMDA0NDQAMDAwMDAwMAAwMDAwMDAwADAwMDAwMDAyMjQ3
          ADEzMTQwMTU2MjQxADAxMzQ0MAAgMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
          AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
          AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB1c3RhcgAwMHdoZWVs
          AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAd2hlZWwAAAAAAAAAAAAAAAAA
          ...
          GEM_DATA
        TEMPLATE_OUTPUT

        expect(subject.render_partial "gem_base64_string", locals).to eq expected
      end
    end
  end

  describe "_install_gem.rb.erb" do
    context "for the manageiq-performance gem" do
      let(:locals) {
        {
          :name     => "manageiq-performance",
          :env_name => "MIQPERF"
        }
      }

      it "renders the code for installing manageiq_performance" do
        expected = <<-TEMPLATE_OUTPUT.gsub(/^ */, '')
          ##### Install manageiq-performance #####
          puts "Installing manageiq-performance.gem"

          gem_file = "/tmp/\#{MIQPERF_FULL_GEM_NAME}.gem"
          File.write gem_file, Base64.decode64(MIQPERF_GEM_BUNDLE)

          Gem::Installer.new(gem_file, :install_dir => GEM_INSTALL_DIR).install
        TEMPLATE_OUTPUT

        expect(subject.render_partial "install_gem", locals).to eq expected
      end
    end

    context "for a random gem" do
      let(:locals) {
        {
          :name     => "foobar",
          :env_name => "FOOBAR",
        }
      }

      it "renders the code for installing the random gem" do
        expected = <<-TEMPLATE_OUTPUT.gsub(/^ */, '')
          ##### Install foobar #####
          puts "Installing foobar.gem"

          gem_file = "/tmp/\#{FOOBAR_FULL_GEM_NAME}.gem"
          File.write gem_file, Base64.decode64(FOOBAR_GEM_BUNDLE)

          Gem::Installer.new(gem_file, :install_dir => GEM_INSTALL_DIR).install
        TEMPLATE_OUTPUT

        expect(subject.render_partial "install_gem", locals).to eq expected
      end
    end
  end

  describe "_new_bundler_dependency.rb.erb" do
    context "for the manageiq-performance gem" do
      let(:locals) {
        {
          :name     => "manageiq-performance",
          :env_name => "MIQPERF"
        }
      }

      it "renders the code for adding manageiq_performance to the bundle lockfile" do
        expected = <<-TEMPLATE_OUTPUT.gsub(/^ */, '')
          # Build sources, dependencies and spec for manageiq-performance
          new_gem_version      = Gem::Version.new(MIQPERF_GEM_VERSION)
          new_gem_bundler_src  = Bundler::Source::Path.from_lock "remote" => MIQPERF_INSTALL_LOCATION
          new_gem_bundler_dep  = Bundler::Dependency.new MIQPERF_GEM_NAME, nil, "source" => new_gem_bundler_src
          new_gem_bundler_spec = Bundler::LazySpecification.new MIQPERF_GEM_NAME, new_gem_version, Gem::Platform::RUBY
          new_gem_bundler_spec.source = new_gem_bundler_src

          # Add source, spec, and dependency to existing definition
          definition.dependencies << new_gem_bundler_dep
          definition.send(:sources).send :add_path_source, new_gem_bundler_src.options
          definition.send(:resolve)[new_gem_bundler_spec.identifier] = new_gem_bundler_spec
        TEMPLATE_OUTPUT

        expect(subject.render_partial "new_bundler_dependency", locals).to eq expected
      end
    end

    context "for a random gem" do
      let(:locals) {
        {
          :name     => "foobar",
          :env_name => "FOOBAR"
        }
      }

      it "renders the code for adding manageiq_performance to the bundle lockfile" do
        expected = <<-TEMPLATE_OUTPUT.gsub(/^ */, '')
          # Build sources, dependencies and spec for foobar
          new_gem_version      = Gem::Version.new(FOOBAR_GEM_VERSION)
          new_gem_bundler_src  = Bundler::Source::Path.from_lock "remote" => FOOBAR_INSTALL_LOCATION
          new_gem_bundler_dep  = Bundler::Dependency.new FOOBAR_GEM_NAME, nil, "source" => new_gem_bundler_src
          new_gem_bundler_spec = Bundler::LazySpecification.new FOOBAR_GEM_NAME, new_gem_version, Gem::Platform::RUBY
          new_gem_bundler_spec.source = new_gem_bundler_src

          # Add source, spec, and dependency to existing definition
          definition.dependencies << new_gem_bundler_dep
          definition.send(:sources).send :add_path_source, new_gem_bundler_src.options
          definition.send(:resolve)[new_gem_bundler_spec.identifier] = new_gem_bundler_spec
        TEMPLATE_OUTPUT

        expect(subject.render_partial "new_bundler_dependency", locals).to eq expected
      end
    end
  end
end
