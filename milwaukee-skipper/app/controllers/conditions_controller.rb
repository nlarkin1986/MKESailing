class ConditionsController < ApplicationController
  def show
    @conditions = LakeConditions.current
    render json: @conditions
  end
end
