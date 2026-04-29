module Rails
  module Contact
    class ContactsController < ApplicationController
      before_action :set_contact, only: [:show, :edit, :update, :destroy]

      def index
        @query = params[:q].to_s.strip
        @contacts = Search::Query.new(@query, filters: filter_params).call
      end

      def show; end

      def new
        @contact = Contact.new
        build_default_associations
      end

      def edit; end

      def create
        @contact = Contact.new(contact_params)
        if @contact.save
          enqueue_index(@contact.id)
          redirect_to contact_path(@contact), notice: "Contact created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def update
        if @contact.update(contact_params)
          enqueue_index(@contact.id)
          redirect_to contact_path(@contact), notice: "Contact updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        id = @contact.id
        @contact.destroy!
        IndexContactJob.perform_later(id, remove: true)
        redirect_to contacts_path, notice: "Contact deleted."
      end

      private

      def set_contact
        @contact = Contact.find(params[:id])
        build_default_associations
      end

      def contact_params
        params.require(:contact).permit(
          :given_name, :family_name, :current_city, :departure_city, :region_name, :biography, :sync_eligible,
          emails_attributes: [:id, :value, :label, :primary, :_destroy],
          phones_attributes: [:id, :value, :label, :primary, :_destroy],
          addresses_attributes: [:id, :city, :departure_city, :formatted_value, :label, :_destroy]
        )
      end

      def filter_params
        params.permit(:city, :region, :sync_eligible)
      end

      def enqueue_index(contact_id)
        IndexContactJob.perform_later(contact_id)
      end

      def build_default_associations
        @contact.emails.build if @contact.emails.empty?
        @contact.phones.build if @contact.phones.empty?
        @contact.addresses.build if @contact.addresses.empty?
      end
    end
  end
end
