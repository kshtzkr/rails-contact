module Rails
  module Contact
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
    end
  end
end
