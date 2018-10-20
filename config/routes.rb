Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  post "/slack", to: "slack#get_input"
  root to: "homepage#show"
end
