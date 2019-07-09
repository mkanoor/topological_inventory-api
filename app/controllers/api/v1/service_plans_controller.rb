module Api
  module V1
    class ServicePlansController < ApplicationController
      include Api::V1::Mixins::IndexMixin
      include Api::V1::Mixins::ShowMixin

      def order
        service_plan = model.find(params_for_order[:service_plan_id].to_i)
        task = Task.create!(:tenant => service_plan.tenant, :state => "pending", :status => "ok")

        messaging_client.publish_message(
          :service => "platform.topological-inventory.operations-openshift",
          :message => "ServicePlan.order",
          :payload => payload_for_order(task, service_plan)
        )

        render :json => {:task_id => task.id}
      rescue ActiveRecord::RecordNotFound
        head :bad_request
      end

      private

      def params_for_order
        @params_for_order ||= params.permit(
          :service_plan_id,
          :service_parameters          => {},
          :provider_control_parameters => {}
        ).to_h
      end

      def payload_for_order(task, service_plan)
        {
          :request_context => ManageIQ::API::Common::Request.current_forwardable,
          :params          => {
            :order_params    => params_for_order,
            :service_plan_id => service_plan.id.to_s,
            :task_id         => task.id.to_s,
          }
        }
      end
    end
  end
end