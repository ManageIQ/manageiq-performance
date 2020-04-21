require 'net/http'
require 'openssl'
require 'logger'
require 'uri'

module ManageIQPerformance
  class Requestor
    CSRF_TAG_REGEX   = /meta.*name="csrf-token".*$/
    CSRF_TOKEN_REGEX = /content="([^"]*)".*/

    HTML_HEADERS     = {'Accept' => 'text/html'}
    JSON_HEADERS     = {'Accept' => 'application/json'}
    PERF_HEADERS     = {
                         'WITH_PERFORMANCE_MONITORING' => 'true',
                         'MIQ_PERF_STACKPROF_RAW'      => 'true'
                       }
    UI_HEADERS       = PERF_HEADERS.merge(HTML_HEADERS)
    API_HEADERS      = PERF_HEADERS.merge(JSON_HEADERS)


    # Deprecated
    BASE_HEADERS     = HTML_HEADERS
    DEFAULT_HEADERS  = UI_HEADERS

    attr_accessor :uri, :api, :session, :headers

    def initialize(options={})
      @uri         = URI.parse(options[:host] || "http://localhost:3000")
      @api         = options[:api] || false
      @headers     = (api ? API_HEADERS : UI_HEADERS).merge(options[:headers] || {})
      @logger      = options[:logger] || Logger.new(STDOUT)
      @ignore_cert = options[:ignore_ssl] || false

      require 'json' if api

      login
    end

    def get(path, options={})
      nethttp_request(:get, path, options)
    end

    def patch(path, options={})
      nethttp_request(:patch, path, options)
    end

    def post(path, options={})
      nethttp_request(:post, path, options)
    end

    def put(path, options={})
      nethttp_request(:put, path, options)
    end

    private

    def nethttp_request(method, path, options={})
      payload       = build_request_payload_for method, options
      request_args  = Array(payload)
      request_args << build_headers(options[:headers])

      login_route = %w[/ /api/auth /dashboard/authenticate].include?(path)

      unless login_route  # logged already
        log "--> making #{method.to_s.upcase} request: #{path}"
      end

      http.send(method, path, *request_args).tap do |response|
        if api && path == '/api/auth'
          @session         = JSON.parse(response.body)["auth_token"]
        elsif not api
          set_cookie_field = response.get_fields('set-cookie')
          @session         = set_cookie_field[0] if set_cookie_field
        end
        log response.body.class if options[:inspect_body] && !login_route
        log response.body       if options[:inspect_body] && !login_route
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
      if api
        nethttp_request :get, "/api/auth", :headers => hdrs
      else
        nethttp_request :post, "/dashboard/authenticate",
                        :params  => credentials, :headers => hdrs
      end
    end

    def build_request_payload_for method, request_options
      return request_options[:params] || '' if method == :post && !request_options[:data]
      return request_options[:data]         if method != :get && request_options[:data]
      nil
    end

    def csrf_token
      log "--> getting csrf_token..." unless @csrf_token
      @csrf_token ||= nethttp_request(:get, '/', :headers => HTML_HEADERS)
                        .body.scan(CSRF_TAG_REGEX).first.to_s
                        .match(CSRF_TOKEN_REGEX) {|match| match[1] }
    end

    def login_headers
      if api
        JSON_HEADERS.merge({
          # Value calculated from the same method found in
          # Net::HTTPHeader#basic_encode, which is what is used in the
          # `#basic_auth` method.
          'authorization' => 'Basic ' + ["#{username}:#{password}"].pack('m0')
        })
      else
        HTML_HEADERS.merge({
          'X-CSRF-Token' => csrf_token.to_s, # first so session is set correctly
          'Cookie'       => @session,
        })
      end
    end

    def full_request_headers
      timestamp = (Time.now.to_f * 1000000).to_i.to_s
      token_hdr = api ? "X-Auth-Token" : "Cookie"
      @headers.merge({
        token_hdr            => @session,
        'MIQ_PERF_TIMESTAMP' => timestamp
      })
    end

    def build_headers custom_headers = nil
      (custom_headers || full_request_headers).tap do |headers|
        headers.delete_if { |k,v| v.nil? }
      end
    end

    def credentials
      URI.encode_www_form 'user_name'     => username,
                          'user_password' => password
    end

    def username
      ManageIQPerformance.config.requestor.username
    end

    def password
      ManageIQPerformance.config.requestor.password
    end

    def poltergeist_enabled?
      @poltergeist_enabled ||= defined?(ManageIQPerformance::Requestor::Poltergiest)
    end

    def log(msg)
      @logger.debug msg
    end

    def using_ssl?
      uri.port == 443
    end

    def ignore_ssl_cert?
      using_ssl? && @ignore_cert
    end
  end
end
