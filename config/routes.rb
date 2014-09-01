FFC::Application.routes.draw do

  resources :drafts

  root "leagues#index"

  post "/addpick" => "drafts#add_pick"

  get "/keepers" => "recruits#keepers"

  get "/simdraft" => "drafts#predict_draft"

  get "/livedraft" => "drafts#live_draft"

  get '/drafts/:league_id/new_draft' => "drafts#new_draft"

  post "/drafts/:league_id/init_draft" => "drafts#initialize_draft"

  get "/leagues/:league/recruits" => "leagues#list_recruits"

  get "/add_recruits/:league_id" => "leagues#add_recruits_to_league"

  post "/upload_recruits/:league_id" => "recruits#upload_recruits"

  post "create_league_teams/:league_id" => "teams#create_league_teams"

  post "initialize_teams/:league_id"  => 'teams#initialize_teams'

  resources :demands

  resources :franchises

  resources :plays

  resources :recruits

  resources :positions

  resources :leagues

  resources :teams

  resources :players

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
