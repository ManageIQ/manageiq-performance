require "manageiq_performance/stacktrace_cleaners/miq"

describe ManageIQPerformance::StacktraceCleaners::Miq do
  describe "#call" do
    before do
      expect(Bundler).to receive(:home).and_return("/home/user/.gem/ruby/2.5.8/bundler")
      expect(Rails).to   receive(:root).and_return(Pathname.new("/home/user/code/manageiq")).twice
    end

    it "returns the stacktrace with only miq related code" do
      cleaner  = described_class.new
      result   = cleaner.call(stacktrace)
      expected = [
        "manageiq-ui-classic/app/controllers/application_controller/miq_request_methods.rb:1030:in `workflow_instance_from_vars'",
        "manageiq-ui-classic/app/controllers/application_controller/miq_request_methods.rb:887:in `prov_set_form_vars'",
        "manageiq-ui-classic/app/controllers/catalog_controller.rb:202:in `atomic_st_edit'",
        "manageiq-ui-classic/app/controllers/catalog_controller.rb:107:in `servicetemplate_edit'",
        "manageiq-ui-classic/app/controllers/application_controller/explorer.rb:196:in `generic_x_button'",
        "manageiq-ui-classic/app/controllers/catalog_controller.rb:77:in `x_button'",
        "manageiq-content-97639bc084e0/content/automate",
        "manageiq-ui-classic/spec/controllers/catalog_controller_spec.rb:225:in `block (4 levels) in <top (required)>'",
        "manageiq-ui-classic/spec/manageiq/spec/spec_helper.rb:65:in `block (3 levels) in <top (required)>'",
        "spec/support/evm_spec_helper.rb:34:in `clear_caches'",
        "manageiq-ui-classic/spec/manageiq/spec/spec_helper.rb:65:in `block (2 levels) in <top (required)>'",
      ]

      expect(result).to eq(expected)
    end
  end

  # Putting this at the bottom so it is out of the way, but still in scope
  #
  # Pulled from a spec failure in manageiq-ui-classic, but should do the trick
  let(:stacktrace) do
    [
      "/home/user/code/manageiq-ui-classic/app/controllers/application_controller/miq_request_methods.rb:1030:in `workflow_instance_from_vars'",
      "/home/user/code/manageiq-ui-classic/app/controllers/application_controller/miq_request_methods.rb:887:in `prov_set_form_vars'",
      "/home/user/code/manageiq-ui-classic/app/controllers/catalog_controller.rb:202:in `atomic_st_edit'",
      "/home/user/code/manageiq-ui-classic/app/controllers/catalog_controller.rb:107:in `servicetemplate_edit'",
      "/home/user/code/manageiq-ui-classic/app/controllers/application_controller/explorer.rb:196:in `generic_x_button'",
      "/home/user/code/manageiq-ui-classic/app/controllers/catalog_controller.rb:77:in `x_button'",
      "/home/user/.gem/ruby/2.5.8/gems/actionpack-6.0.3.4/lib/action_controller/metal/basic_implicit_render.rb:6:in `send_action'",
      "/home/user/.gem/ruby/2.5.8/gems/actionpack-6.0.3.4/lib/abstract_controller/base.rb:195:in `process_action'",
      "/home/user/.gem/ruby/2.5.8/gems/actionpack-6.0.3.4/lib/action_controller/metal/rendering.rb:30:in `process_action'",
      "/home/user/.gem/ruby/2.5.8/gems/actionpack-6.0.3.4/lib/abstract_controller/callbacks.rb:42:in `block in process_action'",
      "/home/user/.gem/ruby/2.5.8/gems/activesupport-6.0.3.4/lib/active_support/callbacks.rb:135:in `run_callbacks'",
      "/home/user/.gem/ruby/2.5.8/bundler/gems/manageiq-content-97639bc084e0/content/automate",
      "/home/user/.gem/ruby/2.5.8/gems/actionpack-6.0.3.4/lib/abstract_controller/callbacks.rb:41:in `process_action'",
      "/home/user/.gem/ruby/2.5.8/gems/actionpack-6.0.3.4/lib/action_controller/metal/rescue.rb:22:in `process_action'",
      "/home/user/.gem/ruby/2.5.8/gems/actionpack-6.0.3.4/lib/action_controller/metal/instrumentation.rb:33:in `block in process_action'",
      "/home/user/.gem/ruby/2.5.8/gems/activesupport-6.0.3.4/lib/active_support/notifications.rb:180:in `block in instrument'",
      "/home/user/.gem/ruby/2.5.8/gems/activesupport-6.0.3.4/lib/active_support/notifications/instrumenter.rb:24:in `instrument'",
      "/home/user/.gem/ruby/2.5.8/gems/activesupport-6.0.3.4/lib/active_support/notifications.rb:180:in `instrument'",
      "/home/user/.gem/ruby/2.5.8/gems/actionpack-6.0.3.4/lib/action_controller/metal/instrumentation.rb:32:in `process_action'",
      "/home/user/.gem/ruby/2.5.8/gems/actionpack-6.0.3.4/lib/action_controller/metal/params_wrapper.rb:245:in `process_action'",
      "/home/user/.gem/ruby/2.5.8/gems/activerecord-6.0.3.4/lib/active_record/railties/controller_runtime.rb:27:in `process_action'",
      "/home/user/.gem/ruby/2.5.8/gems/actionpack-6.0.3.4/lib/abstract_controller/base.rb:136:in `process'",
      "/home/user/.gem/ruby/2.5.8/gems/actionview-6.0.3.4/lib/action_view/rendering.rb:39:in `process'",
      "/home/user/.gem/ruby/2.5.8/gems/actionpack-6.0.3.4/lib/action_controller/metal.rb:190:in `dispatch'",
      "/home/user/.gem/ruby/2.5.8/gems/actionpack-6.0.3.4/lib/action_controller/test_case.rb:517:in `process'",
      "/home/user/.gem/ruby/2.5.8/gems/rails-controller-testing-1.0.5/lib/rails/controller/testing/template_assertions.rb:62:in `process'",
      "/home/user/.gem/ruby/2.5.8/gems/actionpack-6.0.3.4/lib/action_controller/test_case.rb:403:in `post'",
      "/home/user/code/manageiq-ui-classic/spec/controllers/catalog_controller_spec.rb:225:in `block (4 levels) in <top (required)>'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example.rb:262:in `instance_exec'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example.rb:262:in `block in run'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example.rb:508:in `block in with_around_and_singleton_context_hooks'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example.rb:465:in `block in with_around_example_hooks'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/hooks.rb:486:in `block in run'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/hooks.rb:626:in `block in run_around_example_hooks_for'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example.rb:350:in `call'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-rails-4.0.2/lib/rspec/rails/example/controller_example_group.rb:191:in `block (2 levels) in <module:ControllerExampleGroup>'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example.rb:455:in `instance_exec'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example.rb:455:in `instance_exec'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/hooks.rb:390:in `execute_with'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/hooks.rb:628:in `block (2 levels) in run_around_example_hooks_for'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example.rb:350:in `call'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-rails-4.0.2/lib/rspec/rails/adapters.rb:75:in `block (2 levels) in <module:MinitestLifecycleAdapter>'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example.rb:455:in `instance_exec'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example.rb:455:in `instance_exec'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/hooks.rb:390:in `execute_with'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/hooks.rb:628:in `block (2 levels) in run_around_example_hooks_for'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example.rb:350:in `call'",
      "/home/user/code/manageiq-ui-classic/spec/manageiq/spec/spec_helper.rb:65:in `block (3 levels) in <top (required)>'",
      "/home/user/code/manageiq/spec/support/evm_spec_helper.rb:34:in `clear_caches'",
      "/home/user/code/manageiq-ui-classic/spec/manageiq/spec/spec_helper.rb:65:in `block (2 levels) in <top (required)>'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example.rb:455:in `instance_exec'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example.rb:455:in `instance_exec'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/hooks.rb:390:in `execute_with'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/hooks.rb:628:in `block (2 levels) in run_around_example_hooks_for'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example.rb:350:in `call'",
      "/home/user/.gem/ruby/2.5.8/gems/webmock-3.11.0/lib/webmock/rspec.rb:37:in `block (2 levels) in <top (required)>'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example.rb:455:in `instance_exec'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example.rb:455:in `instance_exec'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/hooks.rb:390:in `execute_with'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/hooks.rb:628:in `block (2 levels) in run_around_example_hooks_for'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example.rb:350:in `call'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/hooks.rb:629:in `run_around_example_hooks_for'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/hooks.rb:486:in `run'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example.rb:465:in `with_around_example_hooks'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example.rb:508:in `with_around_and_singleton_context_hooks'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example.rb:259:in `run'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example_group.rb:644:in `block in run_examples'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example_group.rb:640:in `map'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example_group.rb:640:in `run_examples'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example_group.rb:606:in `run'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example_group.rb:607:in `block in run'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example_group.rb:607:in `map'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example_group.rb:607:in `run'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example_group.rb:607:in `block in run'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example_group.rb:607:in `map'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/example_group.rb:607:in `run'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/runner.rb:121:in `block (3 levels) in run_specs'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/runner.rb:121:in `map'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/runner.rb:121:in `block (2 levels) in run_specs'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/configuration.rb:2067:in `with_suite_hooks'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/runner.rb:116:in `block in run_specs'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/reporter.rb:74:in `report'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/runner.rb:115:in `run_specs'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/runner.rb:89:in `run'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/runner.rb:71:in `run'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/lib/rspec/core/runner.rb:45:in `invoke'",
      "/home/user/.gem/ruby/2.5.8/gems/rspec-core-3.10.1/exe/rspec:4:in `<main>'"
    ]
  end
end
