require 'net/http'
require 'logger'
require 'uri'

module MiqPerformance
  class Requestor
    CSRF_TAG_REGEX   = /meta.*name="csrf-token".*$/
    CSRF_TOKEN_REGEX = /content="([^"]*)".*/

    BASE_HEADERS     = {'Accept' => 'text/html'}
    DEFAULT_HEADERS  = {
                         'WITH_PERFORMANCE_MONITORING' => 'true',
                         'MIQ_PERF_STACKPROF_RAW' => 'true'
                       }.merge(BASE_HEADERS)

    attr_accessor :uri, :session, :headers

    def initialize(options={})
      @uri         = URI.parse(options[:host] || "http://localhost:3000")
      @headers     = DEFAULT_HEADERS.merge(options[:headers] || {})
      @logger      = options[:logger] || Logger.new(STDOUT)
      @ignore_cert = options[:ignore_ssl] || false

      login
    end

    def get(path, options={})
      nethttp_request(:get, path, options)
    end

    def post(path, options={})
      nethttp_request(:post, path, options)
    end

    private

    def nethttp_request(method, path, options={})
      payload       = (options[:params] || '') if method == :post
      request_args  = Array(payload)
      request_args << (options[:headers] || full_request_headers)

      unless %w[/ /dashboard/authenticate].include?(path) # logged already
        log "--> making #{method.to_s.upcase} request: #{path}"
      end

      http.send(method, path, *request_args).tap do |response|
        set_cookie_field = response.get_fields('set-cookie')
        @session         = set_cookie_field[0] if set_cookie_field
      end
    end

    def http
      @http ||= Net::HTTP.new(uri.host, uri.port).tap {|http|
                  http.use_ssl = true if using_ssl?
                  http.read_timeout = 300 # we have some big requests...
                  http.verify_mode = OpenSSL::SSL::VERIFY_NONE if ignore_ssl_cert?
                }
    end

    def login
      hdrs = login_headers
      log "--> logging in..."
      nethttp_request :post, "/dashboard/authenticate",
                  :params  => credentials, :headers => hdrs
    end

    def csrf_token
      log "--> getting csrf_token..." unless @csrf_token
      @csrf_token ||= nethttp_request(:get, '/', :headers => BASE_HEADERS)
                        .body.scan(CSRF_TAG_REGEX).first.to_s
                        .match(CSRF_TOKEN_REGEX)[1]
    end

    def login_headers
      BASE_HEADERS.merge({
        'X-CSRF-Token' => csrf_token, # first so session is set correctly
        'Cookie'       => @session,
      })
    end

    def full_request_headers
      timestamp = (Time.now.to_f * 1000000).to_i.to_s
      @headers.merge({
        'X-CSRF-Token'       => csrf_token, # first so session is set correctly
        'Cookie'             => @session,
        'MIQ_PERF_TIMESTAMP' => timestamp
      })
    end

    def credentials
      URI.encode_www_form 'user_name'     => username,
                          'user_password' => password
    end

    def username
      MiqPerformance.config.requestor.username
    end

    def password
      MiqPerformance.config.requestor.password
    end

    def poltergeist_enabled?
      @poltergeist_enabled ||= defined?(MiqPerformance::Requestor::Poltergiest)
    end

    def log(msg)
      @logger.debug msg
    end

    def using_ssl?
      uri.port == 443
    end

    def ignore_ssl_cert?
      using_ssl? && ignore_cert?
    end
  end
end
