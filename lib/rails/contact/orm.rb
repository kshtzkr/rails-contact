module Rails
  module Contact
    module ORM
      module_function

      def adapter
        ENV.fetch("DEVISE_ORM", "active_record")
      end

      def active_record?
        adapter == "active_record"
      end

      def mongoid?
        adapter == "mongoid"
      end
    end
  end
end
