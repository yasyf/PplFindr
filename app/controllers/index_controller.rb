require 'possible_email'

class IndexController < ApplicationController

  def index
  end

  def info
    r_params = result_params
    r_params[:domains] = r_params[:domains].present? ? r_params[:domains].split(',').map { |x| x.strip } : []
    result_set = ResultSet.find_or_create r_params
    render json: result_set.get_results
  end

  def result_params
    params.permit(:first_name, :last_name, :email, :domains)
  end

end
