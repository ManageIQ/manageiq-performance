module ManageIQPerformance
  module Middlewares
    module EnvDebug

      private

      def env_debug_initialize; end
      def env_debug_start env;  end

      # There is a performance hit here as we wait for the report to be written
      # to disk, but it will not be shown in the report.
      def env_debug_finish env
        save_report env, :env_debug,
                    env_debug_short_form_data,
                    env_debug_long_form_data(env)
      end

      def env_debug_long_form_data env
        proc do
          {
            :keys                                          => env.keys,
            # 'rack.version'                                 => env['rack.version'],
            # 'rack.errors'                                  => env['rack.errors'],
            # 'rack.multithread'                             => env['rack.multithread'],
            # 'rack.multiprocess'                            => env['rack.multiprocess'],
            # 'rack.run_once'                                => env['rack.run_once'],
            'SCRIPT_NAME'                                  => env['SCRIPT_NAME'],
            'QUERY_STRING'                                 => env['QUERY_STRING'],
            'SERVER_PROTOCOL'                              => env['SERVER_PROTOCOL'],
            'SERVER_SOFTWARE'                              => env['SERVER_SOFTWARE'],
            'GATEWAY_INTERFACE'                            => env['GATEWAY_INTERFACE'],
            'REQUEST_METHOD'                               => env['REQUEST_METHOD'],
            'REQUEST_PATH'                                 => env['REQUEST_PATH'],
            'REQUEST_URI'                                  => env['REQUEST_URI'],
            'HTTP_VERSION'                                 => env['HTTP_VERSION'],
            'HTTP_HOST'                                    => env['HTTP_HOST'],
            'HTTP_CONNECTION'                              => env['HTTP_CONNECTION'],
            'HTTP_UPGRADE_INSECURE_REQUESTS'               => env['HTTP_UPGRADE_INSECURE_REQUESTS'],
            'HTTP_USER_AGENT'                              => env['HTTP_USER_AGENT'],
            'HTTP_ACCEPT'                                  => env['HTTP_ACCEPT'],
            'HTTP_ACCEPT_ENCODING'                         => env['HTTP_ACCEPT_ENCODING'],
            'HTTP_ACCEPT_LANGUAGE'                         => env['HTTP_ACCEPT_LANGUAGE'],
            'HTTP_COOKIE'                                  => env['HTTP_COOKIE'],
            'HTTP_IF_NONE_MATCH'                           => env['HTTP_IF_NONE_MATCH'],
            'SERVER_NAME'                                  => env['SERVER_NAME'],
            'SERVER_PORT'                                  => env['SERVER_PORT'],
            'PATH_INFO'                                    => env['PATH_INFO'],
            'REMOTE_ADDR'                                  => env['REMOTE_ADDR'],
            # 'puma.socket'                                  => env['puma.socket'],
            # 'rack.hijack?'                                 => env['rack.hijack?'],
            # 'rack.hijack'                                  => env['rack.hijack'],
            # 'rack.input'                                   => env['rack.input'],
            # 'rack.url_scheme'                              => env['rack.url_scheme'],
            # 'rack.after_reply'                             => env['rack.after_reply'],
            # 'puma.config'                                  => env['puma.config'],
            # 'action_dispatch.parameter_filter'             => env['action_dispatch.parameter_filter'],
            # 'action_dispatch.redirect_filter'              => env['action_dispatch.redirect_filter'],
            # 'action_dispatch.secret_token'                 => env['action_dispatch.secret_token'],
            # 'action_dispatch.secret_key_base'              => env['action_dispatch.secret_key_base'],
            # 'action_dispatch.show_exceptions'              => env['action_dispatch.show_exceptions'],
            # 'action_dispatch.show_detailed_exceptions'     => env['action_dispatch.show_detailed_exceptions'],
            # 'action_dispatch.logger'                       => env['action_dispatch.logger'],
            # 'action_dispatch.backtrace_cleaner'            => env['action_dispatch.backtrace_cleaner'],
            # 'action_dispatch.key_generator'                => env['action_dispatch.key_generator'],
            # 'action_dispatch.http_auth_salt'               => env['action_dispatch.http_auth_salt'],
            # 'action_dispatch.signed_cookie_salt'           => env['action_dispatch.signed_cookie_salt'],
            # 'action_dispatch.encrypted_cookie_salt'        => env['action_dispatch.encrypted_cookie_salt'],
            # 'action_dispatch.encrypted_signed_cookie_salt' => env['action_dispatch.encrypted_signed_cookie_salt'],
            # 'action_dispatch.cookies_serializer'           => env['action_dispatch.cookies_serializer'],
            # 'action_dispatch.cookies_digest'               => env['action_dispatch.cookies_digest'],
            # 'action_dispatch.routes'                       => env['action_dispatch.routes'],
            'ROUTES_70315966792760_SCRIPT_NAME'            => env['ROUTES_70315966792760_SCRIPT_NAME'],
            'ORIGINAL_FULLPATH'                            => env['ORIGINAL_FULLPATH'],
            'ORIGINAL_SCRIPT_NAME'                         => env['ORIGINAL_SCRIPT_NAME'],
            'HTTP_WITH_PERFORMANCE_MONITORING'             => env['HTTP_WITH_PERFORMANCE_MONITORING'],
            # 'action_dispatch.request_id'                   => env['action_dispatch.request_id'],
            # 'action_dispatch.remote_ip'                    => env['action_dispatch.remote_ip'],
            # 'rack.session'                                 => env['rack.session'],
            # 'rack.session.options'                         => env['rack.session.options'],
            # 'action_dispatch.request.path_parameters'      => env['action_dispatch.request.path_parameters'],
            # 'action_controller.instance'                   => env['action_controller.instance'],
            # 'action_dispatch.request.content_type'         => env['action_dispatch.request.content_type'],
            # 'action_dispatch.request.request_parameters'   => env['action_dispatch.request.request_parameters'],
            # 'rack.request.query_string'                    => env['rack.request.query_string'],
            # 'rack.request.query_hash'                      => env['rack.request.query_hash'],
            # 'action_dispatch.request.query_parameters'     => env['action_dispatch.request.query_parameters'],
            # 'action_dispatch.request.parameters'           => env['action_dispatch.request.parameters'],
            # 'action_dispatch.request.formats'              => env['action_dispatch.request.formats'],
            # 'rack.request.cookie_hash'                     => env['rack.request.cookie_hash'],
            # 'rack.request.cookie_string'                   => env['rack.request.cookie_string'],
            # 'secure_headers_request_config'                => env['secure_headers_request_config']
          }
        end
      end

      def env_debug_short_form_data
        proc { {} }
      end
    end
  end
end
