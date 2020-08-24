Rails.application.routes.draw do
  root 'admin#index'

  resources :orders, only: [:index, :show], param: :number

  resources :reports, only: :index do
  end
  get 'reports/coupons', to: 'reports#coupons'
  get 'reports/sales', to: 'reports#sales'
end
