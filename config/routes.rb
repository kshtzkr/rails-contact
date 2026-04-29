Rails::Contact::Engine.routes.draw do
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
