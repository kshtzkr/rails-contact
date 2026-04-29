Rails::Contact::Engine.routes.draw do
  post "/bulk_destroy", to: "contacts#bulk_destroy", as: :bulk_destroy_contacts
  post "/merge", to: "contacts#merge", as: :merge_contacts
  get "/", to: "contacts#index", as: :contacts
  get "/new", to: "contacts#new", as: :new_contact
  post "/", to: "contacts#create"
  get "/:id", to: "contacts#show", as: :contact
  get "/:id/edit", to: "contacts#edit", as: :edit_contact
  patch "/:id", to: "contacts#update"
  put "/:id", to: "contacts#update"
  delete "/:id", to: "contacts#destroy"
  root to: "contacts#index"
end
