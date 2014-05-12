class FoldersController < ApplicationController
  
  def create
    folder = Folder.new(:name => folder_attributes[:name], :creator_id => current_user.id, :updater_id => current_user.id)
    
    # document numbers are from the document page
    document_numbers = folder_attributes[:document_numbers]

    # clipping ids are from the clippings/folder pages
    if folder_attributes[:clipping_ids]
      clipping_ids = folder_attributes[:clipping_ids].split(',')
    end

    if folder.save
      if document_numbers
        document_numbers.each do |document_number|
          clipping = Clipping.new(:document_number => document_number, :folder_id => folder.id, :user_id => current_user.id)
          clipping.save
        end
      elsif clipping_ids
        clipping_ids.each do |id|
          clipping = Clipping.find(id)
          clipping.update_attributes(:folder_id => folder.id)
        end
      end
    
      folder.reload #ensure our folder object is up-to-date

      # from the document page we need to send back document numbers
      # for the clippings pages we need to send back the ids of the clippings
      documents = document_numbers.present? ? folder.document_numbers : clipping_ids

      render :json => {:folder => {:name => folder.name, :slug => folder.slug, :doc_count => folder.clippings.count, :documents => documents } }
    else
      if folder.errors[:base].present?
        errors = folder.errors[:base]
      else
        errors = folder.errors.messages.map{|key, value| value}.flatten
      end
      render :text => {:errors => errors}.to_json, :status => 400
    end
  end

  def show
    @folders   = FolderDecorator.decorate( Folder.scoped(:conditions => {:creator_id => current_user.id}).all )
    @folder    = Folder.find_by_user_and_slug(current_user, params[:id])
    raise ActiveRecord::RecordNotFound unless @folder.present?

    @clippings = @folder.clippings.present? ? ClippingDecorator.decorate(@folder.clippings) : []
    
    render 'clippings/index', :layout => "application"
  end

  private

  def folder_attributes
    params.require(:folder).permit(:name, :clipping_ids, :document_numbers => [])
  end
end
