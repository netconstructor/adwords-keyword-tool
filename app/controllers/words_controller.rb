class WordsController < InheritedResources::Base
  before_filter :authenticate_user!
  belongs_to :user  
  actions :index, :new, :create, :destroy
  
  ## Exception Handling
  class NoCredentialsError < StandardError
  end

  rescue_from NoCredentialsError, :with => :handle_credentials_exception
    
  def create
    @word = Word.new(params[:word])
    if params[:word][:phrase] == "new"
      redirect_to @word, :notice => "\"New\" is a reserved word. Cannot create keyword named \"new\"."
    else
      adwords = TargetingIdeaService.new :limit => 10
      @words = adwords.suggestions(@word)
      unless @words.empty?
        redirect_to user_words_path(current_user)
      else
        flash[:alert] = "No results for query."
        redirect_to user_words_path(current_user)
      end
    end
  end

  def destroy  
    destroy! { collection_url }
  end
  
  protected
    def begin_of_association_chain
      @current_user
    end

  private

  def handle_credentials_exception
    flash[:alert] = "Access credentials for AdWords API not set."
    redirect_to root_url
  end
end