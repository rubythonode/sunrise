module Sunrise
  class ManagerController < Sunrise::ApplicationController
    before_filter :build_record, :only => [:new, :create]
    before_filter :find_record, :only => [:show, :edit, :update, :destroy]
    before_filter :authorize_resource
    
    helper_method :abstract_model, :apply_scope, :scoped_index_path, :search_wrapper
    
    respond_to :html, :xml, :json
    
    def index
      @records = abstract_model.apply_scopes(params)
      
      respond_with(@records) do |format|
        format.html { render_with_scope(abstract_model.current_list) }
      end
    end
    
    def show
      respond_with(@record) do |format|
        format.html { render_with_scope } 
      end
    end
    
    def new
      respond_with(@record) do |format|
        format.html { render_with_scope } 
      end
    end
    
    def create
      @record.update_attributes(abstract_model.attrs, :as => current_user.role_symbol)
      respond_with(@record, :location => redirect_after_update)
    end
    
    def edit
      respond_with(@record) do |format|
        format.html { render_with_scope } 
      end
    end
    
    def update
      @record.update_attributes(abstract_model.attrs, :as => current_user.role_symbol)
      respond_with(@record, :location => redirect_after_update)
    end
    
    def destroy
      @record.destroy
      respond_with(@record, :location => scoped_index_path)
    end
    
    def export
      @records = abstract_model.export_scope(params)
      options = { :filename => abstract_model.export_filename,
                  :columns => abstract_model.export_columns }
      
      respond_to do |format|
        format.xml  { render :xml => @records }
        format.json { render :json => @records }
        format.csv  { render options.merge(:csv => @records) }
        
        if defined?(Mime::XLSX)
          format.xlsx { render options.merge(:xlsx => @records) }
        end
      end
    end
    
    def sort
      abstract_model.update_sort_column(params[:ids])
      respond_with(true)
    end
    
    protected
    
      def find_model
        @abstract_model = Utils.get_model(params[:model_name], params)
        raise ActiveRecord::RecordNotFound, "Sunrise model #{params[:model_name]} not found" if @abstract_model.nil?
        @abstract_model
      end
      
      def abstract_model
        @abstract_model ||= find_model
      end
      
      def build_record
        @record = abstract_model.build_record
      end
      
      def find_record
        @record = abstract_model.model.find(params[:id])
      end
      
      # Render a view for the specified scope. Turned off by default.
      # Accepts just :controller as option.
      def render_with_scope(scope = nil, action = self.action_name, path = self.controller_path)
        templates = [ [path, action] ]
        templates << [path, scope, action] if scope
        
        if Sunrise::Config.scoped_views?
          templates << [path, abstract_model.scoped_path, scope, action]
        end
        
        templates.reverse.each do |keys|
          name = File.join(*keys.compact.map(&:to_s))
          return render(:template => name) if template_exists?(name)
        end
      end
      
      def apply_scope(scope, path = self.controller_path)
        templates = [ [path, scope] ]
        templates << [ path, abstract_model.current_list, scope ]
        
        if Sunrise::Config.scoped_views?
          templates << [ path, abstract_model.scoped_path, scope ]
          templates << [ path, abstract_model.scoped_path, abstract_model.current_list, scope ]
        end
        
        templates.reverse.each do |keys|
          name = File.join(*keys.compact.map(&:to_s))
          return name if template_exists?(name, nil, true)
        end
        
        # not found ... try render first
        templates.first.join('/')
      end
      
      def authorize_resource
        authorize!(action_name, @record || abstract_model.model, :context => :sunrise)
      end
      
      def scoped_index_path(options = {})
        options = options.merge(abstract_model.parent_hash)
        query = Rack::Utils.parse_query(cookies[:params])
        
        index_path(query.merge(options))
      end
      
      def redirect_after_update
        if abstract_model.without_list?
          index_path(:model_name => abstract_model.scoped_path)
        else
          scoped_index_path
        end
      end
      
      def search_wrapper
        @search_wrapper ||= Sunrise::Views::SearchWrapper.new(params[:search])
      end
  end
end
