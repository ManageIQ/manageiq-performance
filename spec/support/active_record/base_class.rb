require "active_support/core_ext/kernel/reporting"

class BaseClass < ActiveRecord::Base
  self.abstract_class = true

  self.configurations = ActiveRecord::Base.configurations
  establish_connection :default

  # HACK:  not sure the #RightWay™ to do this
  Kernel.silence_warnings do
    def self.id_increment
      @id_increment ||= 0
      @id_increment  += 1
    end
  end
end

