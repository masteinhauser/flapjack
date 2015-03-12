#!/usr/bin/env ruby

require 'sinatra/base'

module Flapjack
  module Gateways
    class JSONAPI < Sinatra::Base
      module Methods
        module UnscheduledMaintenances

          def self.registered(app)
            app.helpers Flapjack::Gateways::JSONAPI::Helpers::Headers
            app.helpers Flapjack::Gateways::JSONAPI::Helpers::Miscellaneous
            app.helpers Flapjack::Gateways::JSONAPI::Helpers::Resources

            app.class_eval do
              swagger_args = ['unscheduled_maintenances',
                              Flapjack::Data::UnscheduledMaintenance]

              swagger_post(*swagger_args)
              swagger_get(*swagger_args)
              swagger_put(*swagger_args)
              swagger_delete(*swagger_args)
            end

            app.post '/unscheduled_maintenances' do
              status 201
              resource_post(Flapjack::Data::UnscheduledMaintenance,
                'unscheduled_maintenances')
            end

            app.get %r{^/unscheduled_maintenances(?:/)?(.+)?$} do
              requested_unscheduled_maintenances = if params[:captures] && params[:captures][0]
                params[:captures][0].split(',').uniq
              else
                nil
              end

              status 200
              resource_get(Flapjack::Data::UnscheduledMaintenance,
                           'unscheduled_maintenances',
                           requested_unscheduled_maintenances,
                           :sort => :timestamp)
            end

            app.patch %r{^/unscheduled_maintenances/(.+)$} do
              unscheduled_maintenance_ids = params[:captures][0].split(',')

              resource_patch(Flapjack::Data::UnscheduledMaintenance,
                'unscheduled_maintenances', unscheduled_maintenance_ids)
              status 204
            end

          end
        end
      end
    end
  end
end