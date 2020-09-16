class ReportsController < ApplicationController

  def index
  end

  def coupons
    all_coupons
    if coupon_name
      valid_coupon? ? set_coupon_data : flash.alert = "Please enter a valid coupon name."
    end
  end

  def sales
    if dates_present?
      valid_dates? ? set_sales_data : flash.alert = "Please enter valid dates."
    end
  end

  private
  def all_coupons
    @all_coupons ||= Coupon.all
  end

  def coupon_name
    @coupon_name ||= permitted_params[:coupon_name]
  end

  def dates_present?
    permitted_params[:start] || permitted_params[:end]
  end

  def valid_dates?
    return false if start_date.nil? || end_date.nil?
    start_date < end_date
  end

  def valid_coupon?
    all_coupons.map(&:name).include? coupon_name
  end

  def start_date
    @start_date ||= DateTime.parse permitted_params[:start] rescue nil
  end

  def end_date
    @end_date ||= DateTime.parse permitted_params[:end] rescue nil
  end

  # if i had more time, i would consider extracting these queries into service objects, which would
  # allow for better rspec testing. but given the time constraints of this project and the complexity
  # of setting up data for testing database interactions, i decided to keep this simple
  def set_coupon_data
    coupon_id = all_coupons.find_by(name: coupon_name)&.id
    return unless coupon_id
    coupon_order_ids = OrderItem.select(:order_id).where(source_type: 'Coupon', source_id: coupon_id)
    coupon_orders =  Order.select('user_id, building_at').where('orders.id in (?)', coupon_order_ids)
    @orders = coupon_orders.map do |order|
      Order.left_joins(:user).select('user_id, count(*) as count, sum(total) as revenue, users.email as user_email').
        where(user_id: order['user_id']).where('building_at > ?', order['building_at'])
    end.flatten
  end

  def set_sales_data
    return if start_date > end_date
    orders = Order.select('id').where('building_at between ? and ?', start_date, end_date).where.not(state: 'canceled')
    order_ids = orders.pluck(:id).join(', ')
    query = %{
      SELECT source_id, sum(quantity) AS total_sold, sum(price * quantity) AS revenue, products.name AS source_name
      FROM order_items
      LEFT JOIN products ON order_items.source_id = products.id
      WHERE order_id IN (#{order_ids}) AND state = 'sold' AND source_type = 'Product'
      GROUP BY source_id
      ORDER BY source_name
    }
    @order_items = ActiveRecord::Base.connection.execute(query)
  end

  QUERY_PARAMS = %i[coupon_name start end]
  def permitted_params
    params.permit(QUERY_PARAMS)
  end
end
