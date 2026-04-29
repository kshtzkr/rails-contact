module Rails
  module Contact
    class ContactsController < ApplicationController
      include Rails::Contact::Filterable
      METADATA_KEYS = %w[
        prefix middle_name suffix nickname company job_title department website birthday notes
      ].freeze

      before_action :set_contact, only: [ :show, :edit, :update, :destroy ]

      def index
        @query = params[:q].to_s.strip
        @contacts = Search::Query.new(@query, filters: normalized_filters(filter_params)).call
        render "rails/contact/index"
      end

      def show
        render "rails/contact/show"
      end

      def new
        @contact = Contact.new
        build_default_associations
        render "rails/contact/new"
      end

      def edit
        render "rails/contact/edit"
      end

      def create
        @contact = Contact.new(contact_params)
        assign_labels(@contact)
        if @contact.save
          enqueue_index(@contact.id)
          redirect_to contact_path(@contact), notice: "Contact created."
        else
          render "rails/contact/new", status: :unprocessable_entity
        end
      end

      def update
        assign_labels(@contact)
        if @contact.update(contact_params)
          enqueue_index(@contact.id)
          redirect_to contact_path(@contact), notice: "Contact updated."
        else
          render "rails/contact/edit", status: :unprocessable_entity
        end
      end

      def destroy
        id = @contact.id
        @contact.destroy!
        IndexContactJob.perform_later(id, remove: true)
        redirect_to contacts_path, notice: "Contact deleted."
      end

      def bulk_destroy
        ids = params[:ids].to_s.split(",").map(&:to_i).reject(&:zero?).uniq
        Contact.where(id: ids).find_each(&:destroy!)
        redirect_to contacts_path, notice: "#{ids.size} contact(s) deleted."
      end

      def merge
        source_id = params[:source_id]
        target_id = params[:target_id]
        MergeContactsService.new(source_id: source_id, target_id: target_id).call
        redirect_to contact_path(target_id), notice: "Contacts merged."
      rescue StandardError => e
        redirect_to contacts_path, alert: "Merge failed: #{e.message}"
      end

      private

      def set_contact
        @contact = Contact.find(params[:id])
        build_default_associations
      end

      def contact_params
        permitted = params.require(:contact).permit(
          :given_name, :family_name, :current_city, :departure_city, :region_name, :biography, :sync_eligible, :starred, :photo_url,
          :labels_csv,
          metadata: {},
          emails_attributes: [ :id, :value, :label, :primary, :_destroy ],
          phones_attributes: [ :id, :value, :label, :primary, :_destroy ],
          addresses_attributes: [ :id, :city, :departure_city, :formatted_value, :label, :_destroy ],
          websites_attributes: [ :id, :url, :label, :_destroy ],
          events_attributes: [ :id, :event_type, :event_date, :label, :_destroy ]
        )

        metadata = permitted[:metadata].is_a?(ActionController::Parameters) ? permitted[:metadata].to_h : {}
        permitted[:metadata] = metadata.slice(*METADATA_KEYS)
        permitted
      end

      def filter_params
        params.permit(:city, :region, :sync_eligible, :starred)
      end

      def enqueue_index(contact_id)
        IndexContactJob.perform_later(contact_id)
      end

      def build_default_associations
        @contact.emails.build(label: "work") while @contact.emails.size < 2
        @contact.phones.build(label: "mobile") while @contact.phones.size < 2
        @contact.addresses.build if @contact.addresses.empty?
        @contact.websites.build(label: "profile") if @contact.websites.empty?
        @contact.events.build(event_type: "birthday") if @contact.events.empty?
      end

      def assign_labels(contact)
        return unless params.dig(:contact, :labels_csv).present?

        contact.set_labels_from_csv!(params.dig(:contact, :labels_csv))
      end
    end
  end
end
