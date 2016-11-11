require "fileutils"

require "manageiq_performance/configuration"
require "manageiq_performance/reporting/param_builder/id"

module ManageIQPerformance
  module Reporting
    class RequestfileBuilder

      include ParamBuilder::Id

      IGNORED_CONTROLLERS = %w[alert picture static]
      IGNORED_ROUTES = %w[ops#show]

      def self.load requestfile_path=nil
        path = requestfile_path || File.join(filepath, filename)
        new unless File.exists? path

        File.readlines(path)
            .reject { |line| line.strip == "" }
            .map    { |line| build_request line }
      end

      def initialize requestfile_path=nil
        write_request_file requestfile_path
      end

      def routes
        @routes ||= all_routes.select {|route| index_or_show? route }
                              .select {|route| passive?       route }
                              .reject {|route| api_route?     route }
                              .reject {|route| ignored_route? route }
                              .reject {|route| internal?      route }
      end

      private

      def self.build_request line
        parts = line.strip.split(' => ')

        {:method => parts[0].strip, :path => parts[1]}
      end

      def write_request_file requestfile_path
        print "Generating Requestfile"
        path = requestfile_path || default_requestfile
        dir  = File.dirname path
        file = File.basename path

        FileUtils.mkdir_p(dir)

        File.open(File.join(dir, file), 'wb') do |f|
          verb_spacing = routes.map {|r| r.verb.length }.max
          routes.each do |route|
            request_path = build_request_path_for(route)
            if request_path && request_path != ''
              print '.'
              f.puts "#{route.verb.ljust(verb_spacing)} => #{request_path}"
            end
          end
          puts
        end
      end

      def self.filepath
        path = ManageIQPerformance.config.requestor.requestfile_dir ||
                 ManageIQPerformance.config.default_dir
        path.start_with?("/") ? path : File.join(Dir.pwd, path)
      end

      def self.filename
        "Requestfile"
      end

      def default_requestfile
        File.join(self.class.filepath, self.class.filename)
      end

      def controller_action route
       "#{route.requirements[:controller]}##{route.requirements[:action]}"
      end

      ##################
      # Route Builders #
      ##################

      def build_request_path_for route, options={}
        if options[:specs_only]
          route.path.spec.to_s
        else
          params = route.path.names.inject({}) do |result, val|
            case val
            when "id" then find_id_for route, result
            else result
            end
          end
          route.path.build_formatter.evaluate params
        end
      end

      #################
      # Route Filters #
      #################

      def all_routes
        ::Rails.application.routes.set.routes
      end

      # Private: Determines if the route falls under MIQ's definition of a
      # show/index route
      #
      # There a lot of `explorer`/`show_list` routes in ManageIQ, so this
      # includes those in that list
      def index_or_show? route
        route.requirements[:action] &&
          %w[show show_list index explorer].include?(route.requirements[:action])
      end

      # Private: Determines if a routes doesn't modify or delete existing
      # records based on the route VERB only.
      #
      # POST is included here becuase it is used for a lot of the
      # UI functions, not just creating new records.
      def passive? route
        %[GET POST].include? route.verb
      end

      # Private:  Determines if a route is part of the MIQ API
      def api_route? route
        route.requirements[:controller] &&
          route.requirements[:controller].include?("manage_i_q/a_p_i")
      end

      # Private:  Determines if is one we want to ignore
      def ignored_route? route
        route.requirements[:controller] &&
          (IGNORED_ROUTES.include?(controller_action(route)) ||
           IGNORED_CONTROLLERS.include?(route.requirements[:controller]))
      end

      # Private:  Determines if is one we want to ignore
      def internal? route
        route.internal
      end
    end
  end
end
