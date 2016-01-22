class ShipmentsController < ApplicationController
respond_to :json

  def estimate
    weight = (package_params[:weight]).to_i
    dimensions = [(package_params[:length]).to_i,  (package_params[:width]).to_i,  (package_params[:height]).to_i]
    package = ActiveShipping::Package.new(weight, dimensions)
    packages = [package]
    origin = ActiveShipping::Location.new(origin_params)
    destination = ActiveShipping::Location.new(destination_params)

    ups = ups_rates(origin, destination, packages)

    usps = usps_rates(origin, destination, packages)
    rates = ups + usps
    render :json => rates.as_json, :status => :ok
  end

private

  def package_params
    params.require(:package).permit(:weight, :length, :width, :height)
  end

  def origin_params
    params.require(:origin).permit(:country, :state, :province, :city, :zip, :postal_code)
  end

  def destination_params
    params.require(:destination).permit(:country, :state, :province, :city, :zip, :postal_code)
  end


  def ups_rates(origin, destination, packages)
    ups = ActiveShipping::UPS.new(login: ENV['UPS_LOGIN'], password: ENV['UPS_PASSWORD'], key: ENV['UPS_KEY'])
    response = ups.find_rates(origin, destination, packages)

    ups_rate_response = response.rates.sort_by(&:price).collect {|rate| [rate.service_name => { price: rate.price, delivery: rate.delivery_range }] }
  end

  def usps_rates(origin, destination, packages)
    usps = ActiveShipping::USPS.new(login: ENV['USPS_USERNAME'])
    response = usps.find_rates(origin, destination, packages)

    usps_rates = response.rates.sort_by(&:price).collect {|rate| [rate.service_name => { price: rate.price, delivery: rate.delivery_date }] }
  end

end
