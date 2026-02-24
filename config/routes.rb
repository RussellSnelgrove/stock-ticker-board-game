Rails.application.routes.draw do
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end

  post "/graphql", to: "graphql#execute"
  post "/join", to: "sessions#create", as: :join
  mount ActionCable.server => "/cable"

  root "games#index"
end
