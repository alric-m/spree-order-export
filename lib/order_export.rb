require 'spree_core'
require 'order_export_hooks'

module OrderExport
  class Engine < Rails::Engine

    config.autoload_paths += %W(#{config.root}/lib)

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*_decorator*.rb")) do |c|
        Rails.env.production? ? require(c) : load(c)
      end
      reports = {:order_export => {:name => "Order Export", :description => "Order Export Description"},
                 :sales_report => {:name => "Sales Report", :description => "Sales Report By Date"}}
      Spree::Admin::ReportsController::AVAILABLE_REPORTS.merge! reports
      Spree::Admin::ReportsController::AVAILABLE_REPORTS.delete(:sales_total)
      Spree::Admin::ReportsController.send(:require, RUBY_VERSION.split('.')[1].to_i > 8 ? 'csv' : 'fastercsv')
      Spree::Admin::ReportsController.send(:include, OrderExport::ReportsControllerExt)
    end

    config.to_prepare &method(:activate).to_proc
  end
end

