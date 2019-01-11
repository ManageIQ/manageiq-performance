module TemplateHelper
  def render_partial partial, locals = {}
    partial_binding = binding.dup
    set_locals locals, partial_binding

    template = get_template_for partial, true

    ERB.new(template, nil, "-").result(partial_binding)
  end

  def set_locals locals, local_binding
    locals.each do |var, val|
      local_binding.local_variable_set var, val
    end
  end

  def get_template_for template, partial = false
    filename = "#{'_' if partial}#{template}.rb.erb"
    File.read File.join(partial ? partial_dir : template_dir, filename)
  end

  def template_dir
    @template_dir ||= File.expand_path "../../templates", __FILE__
  end

  def partial_dir
    @partial_dir ||= begin
                       dir = File.join template_dir, partial_folder
                       File.expand_path dir, __FILE__
                     end
  end

  def partial_folder
    ""
  end
end
