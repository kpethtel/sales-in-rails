require 'pry'
class OrdersController < ApplicationController

  def index
    orders
  end

  def show
    order
    product_items
  end

  private
  def order
    @order ||=
      Order.includes(:user, :payments, order_items: [:source]).find_by!(number: permitted_params[:number])
  end

  def orders
    @orders ||= Order.includes(:user).all
  end

  def product_items
    @product_items ||= order.order_items.select {|item| item.source_type == "Product" }
  end

  PERMITTED_PARAMS = %i[number]
  def permitted_params
    params.permit(PERMITTED_PARAMS)
  end
end
