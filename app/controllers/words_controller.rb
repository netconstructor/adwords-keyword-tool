class WordsController < InheritedResources::Base
  belongs_to :user  
  actions :index, :new, :create, :destroy
    
  def create  
    create! { collection_url }
  end

  def destroy  
    destroy! { collection_url }
  end
  
  protected
    def begin_of_association_chain
      @current_user
    end
end