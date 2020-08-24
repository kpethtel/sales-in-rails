class ReportsController < ApplicationController

  def index
  end

  def coupons
    all_coupons
    set_coupon_data if coupon_name
  end

  def sales
    set_sales_data if start_date && end_date
  end

  private
  def all_coupons
    @coupons ||= Coupon.all
  end

  def coupon_name
    @coupon_name ||= permitted_params[:coupon_name]
  end

  def start_date
    @start_date ||= permitted_params[:start]&.to_date
  end

  def end_date
    @end_date ||= permitted_params[:end]&.to_date
  end

  def set_coupon_data
    coupon_id = all_coupons.find_by!(name: coupon_name).id
    coupon_order_ids = OrderItem.select(:order_id).where(source_type: 'Coupon', source_id: coupon_id)
    coupon_orders =  Order.select('user_id, building_at').where("orders.id in (?)", coupon_order_ids)
    order_aggregates = coupon_orders.map do |order|
      Order.select("user_id, count(*) as count, sum(total) as revenue").
        where(user_id: order['user_id']).where("building_at > ?", order['building_at'])
    end
    @orders = order_aggregates.map do |order|
      order_details = order.as_json.first
      order_details['user_email'] = User.find(order_details['user_id']).email
      order_details
    end
  end

  def set_sales_data
    return if start_date > end_date
    orders = Order.select('id').where("building_at between ? and ?", start_date, end_date).where.not(state: 'canceled')
    order_ids = orders.pluck(:id).join(', ')
    query = "select source_id, sum(quantity) as total_sold, sum(price * quantity) as revenue from order_items where \
order_id in (#{order_ids}) and state = 'sold' group by source_id"
    @order_items = ActiveRecord::Base.connection.execute(query)
    @order_items.each do |record|
      record['source_name'] = Product.find(record['source_id']).name
    end
  end

  QUERY_PARAMS = %i[coupon_name start end]
  def permitted_params
    params.permit(QUERY_PARAMS)
  end
end
