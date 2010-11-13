AdwordsKeywordTool::Application.routes.draw do
  root :to => "home#index"
  devise_for :users
  resources :users, :only => :show  do
    resources :words, :except => [:edit, :show]
  end
  resources :credentials
end