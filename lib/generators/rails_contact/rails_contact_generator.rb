require "rails/generators"

class RailsContactGenerator < ::Rails::Generators::NamedBase
  def delegate_to_engine_generator
    invoke "rails:contact:contact", [ name ]
  end
end
