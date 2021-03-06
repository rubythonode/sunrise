require 'rails/generators'

module Sunrise
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Creates a Sunrise initializer and copy general files to your application."
      source_root File.expand_path(File.join(File.dirname(__FILE__), 'templates'))

      # ORM configuration
      class_option :orm, :type => :string, :default => "active_record",
        :desc => "Configure ORM active_record/mongoid (by default active_record)"
            
      # copy views
      def copy_views
        directory "views", "app/views"
      end
      
      # copy uploaders
      def copy_uploaders
        directory "uploaders", "app/uploaders"
      end
      
      def copy_configurations
        copy_file('config/seeds.rb', 'db/seeds.rb')
        copy_file("config/#{orm}/sunrise.rb", 'config/initializers/sunrise.rb')
        
        template('config/database.yml', 'config/database.yml.sample')
        template('config/logrotate-config', 'config/logrotate-config.sample')
        template('config/nginx-unicorn', 'config/nginx-unicorn.sample')
        template('config/nginx-passenger', 'config/nginx-passenger.sample')
      end
      
      # copy models
      def copy_models
        directory "models/#{orm}", "app/models/defaults"
        directory "models/sunrise", "app/sunrise"
      end
      
      # Add devise routes
      def add_routes
        route 'root :to => "welcome#index"'
        route "resources :pages, :only => [:show]"
        route "devise_for :users"
        route "mount Sunrise::Engine => '/manage'"
      end
      
      def autoload_paths
        log :autoload_paths, "models/defaults"
        sentinel = /\.autoload_paths\s+\+=\s+\%W\(\#\{config\.root\}\/extras\)\s*$/
      
        code = 'config.autoload_paths += %W(#{config.root}/app/models/defaults #{config.root}/app/sunrise)'
          
        in_root do
          inject_into_file 'config/application.rb', "    #{code}\n", { :after => sentinel, :verbose => false }
        end
      end
      
      def copy_specs
        directory "spec", "spec"
        copy_file('rspec', '.rspec')
      end

      def copy_gitignore
        copy_file('gitignore', '.gitignore')
      end

      def copy_sunrise_assets
        copy_file('assets/plugins.js', 'app/assets/javascripts/sunrise/plugins.js')
        copy_file('assets/plugins.css', 'app/assets/stylesheets/sunrise/plugins.css')
      end
      
      protected
        
        def app_name
          @app_name ||= defined_app_const_base? ? defined_app_name : File.basename(destination_root)
        end

        def defined_app_name
          defined_app_const_base.underscore
        end

        def defined_app_const_base
          Rails.respond_to?(:application) && defined?(Rails::Application) &&
            Rails.application.is_a?(Rails::Application) && Rails.application.class.name.sub(/::Application$/, "")
        end

        alias :defined_app_const_base? :defined_app_const_base

        def app_const_base
          @app_const_base ||= defined_app_const_base || app_name.gsub(/\W/, '_').squeeze('_').camelize
        end

        def app_const
          @app_const ||= "#{app_const_base}::Application"
        end
        
        def app_path
          @app_path ||= Rails.root.to_s
        end

        def orm
          options[:orm] || "active_record"
        end
    end
  end
end
