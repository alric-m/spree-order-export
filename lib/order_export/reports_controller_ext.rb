module OrderExport
  module ReportsControllerExt
    def self.included(base)
      base.class_eval do

        def order_export
          export = !params[:q].nil?
          params[:q] ||= {}
          params[:q][:completed_at_not_null] ||= '1' if Spree::Config[:show_only_complete_orders_by_default]
          @show_only_completed = params[:q][:completed_at_not_null].present?
          params[:q][:s] ||= @show_only_completed ? 'completed_at desc' : 'created_at desc'

          if !params[:q][:created_at_gt].blank?
            params[:q][:created_at_gt] = Time.zone.parse(params[:q][:created_at_gt]).beginning_of_day rescue ""
            format_gt = params[:q][:created_at_gt].strftime('%Y%m%d')
          end

          if !params[:q][:created_at_lt].blank?
            params[:q][:created_at_lt] = Time.zone.parse(params[:q][:created_at_lt]).end_of_day rescue ""
            format_lt = params[:q][:created_at_lt].strftime('%Y%m%d')
          end

          if @show_only_completed
            params[:q][:completed_at_gt] = params[:q].delete(:created_at_gt)
            params[:q][:completed_at_lt] = params[:q].delete(:created_at_lt)
          end

          @search = Spree::Order.ransack(params[:q])
          @orders = @search.result

          render and return unless export

          orders_export = CSV.generate(:col_sep => ",", :row_sep => "\r\n") do |csv|
            headers = [
              t('order_export_ext.header.last_updated'),
              t('order_export_ext.header.completed_at'),
              t('order_export_ext.header.number'),
              t('order_export_ext.header.name'),
              t('order_export_ext.header.address_1'),
              t('order_export_ext.header.address_2'),
              t('order_export_ext.header.city'),
              t('order_export_ext.header.state'),
              t('order_export_ext.header.zipcode'),
              t('order_export_ext.header.country'),
              t('order_export_ext.header.phone'),
              t('order_export_ext.header.email'),
              t('order_export_ext.header.variant_name'),
              t('order_export_ext.header.quantity'),
              t('order_export_ext.header.order_total')
            ]

            csv << headers

            @orders.each do |order|
              order.line_items.each do |line_item|
                csv_line = []
                csv_line << order.updated_at
                csv_line << order.completed_at
                csv_line << order.number

                if order.ship_address
                  csv_line << order.ship_address.full_name || ""
                  csv_line << order.ship_address.address1 || ""
                  csv_line << order.ship_address.address2 || ""
                  csv_line << order.ship_address.city || ""
                  csv_line << order.ship_address.state || ""
                  csv_line << order.ship_address.zipcode || ""
                  csv_line << order.ship_address.country.name || ""
                  csv_line << order.ship_address.phone || ""
                else
                  csv_line << ""
                  csv_line << ""
                  csv_line << ""
                  csv_line << ""
                  csv_line << ""
                  csv_line << ""
                  csv_line << ""
                  csv_line << ""
                end
                csv_line << order.email || ""
                csv_line << line_item.variant.name
                csv_line << line_item.quantity
                csv_line << order.total.to_s
                csv << csv_line
              end
            end
          end

          if format_gt && format_lt
            file_time = [format_gt, format_lt].join('-')
          else
            file_time = Time.now.strftime('%Y%m%d')
          end
          send_data orders_export, :type => 'text/csv', :filename => "Footnotes-orders-#{file_time}.csv"
        end
      end
    end
  end
end

