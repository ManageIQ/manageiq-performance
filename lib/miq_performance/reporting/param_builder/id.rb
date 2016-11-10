module ManageIQPerformance
  module Reporting
    module ParamBuilder
      module Id

        IGNORED_ID_CONTROLLERS = %w[
          consumption
          configuration
          container_topology
          middleware_topology
          network_topology
          subnet_topology
          container_dashboard
          dashboard
        ]

        def find_id_for route, result
          if build_id_for? route
            model    = model_for route
            model_id = model.pluck(:id).sample

            result[:id] = model_id if model_id
          end
          result
        end

        private

        def model_for route
          controller = controller_for route
          model      = model_for_controller controller

          Object.const_get(model)
        end

        def model_for_controller controller
          Object.const_get("#{controller}Controller").model.to_s
        end

        def controller_for route
          route.requirements[:controller]
               .split('_').map(&:capitalize).join
        end

        def build_id_for? route
           ignored_controller?(route) &&
            (route.requirements[:action] == "show" ||
             route.path.required_names.include?("id"))
        end

        def ignored_controller? route
          !IGNORED_ID_CONTROLLERS.include?(route.requirements[:controller])
        end
      end
    end
  end
end
