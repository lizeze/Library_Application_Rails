class BooksController < ApplicationController
  #skip_before_action :check_internal, only: [:internal, :purchase, :procurement_list, :actions, :promote, :promotion_list]
  before_action :set_book, only: [:show, :edit, :update, :destroy]
  helper_method :get_book

  #global promotion list
  $promotion_list = []

  # GET /books
  # GET /books.json
  def index
    @books = Book.all

    #prepare and format genre list
    @genre = get_formatted_genre_list(@books.as_json)
    @genre_id = (params[:genre_id].to_i||1).clamp(1, @genre.length)
    @books_return = filter_book_list_activerecord(@books, @genre, @genre_id)
  end

  # GET /books/1
  # GET /books/1.json
  def show

  end

  # GET /books/new
  def new
    @book = Book.new
  end

  # GET /books/1/edit
  def edit

  end

  # POST /books
  # POST /books.json
  def create
    @book = Book.new(book_params)

    respond_to do |format|
      if @book.save
        format.html { redirect_to @book, notice: 'Book was successfully created.' }
        format.json { render :show, status: :created, location: @book }
      else
        format.html { render :new }
        format.json { render json: @book.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /books/1
  # PATCH/PUT /books/1.json
  def update
    respond_to do |format|
      if @book.update(book_params)
        format.html { redirect_to @book, notice: 'Book was successfully updated.' }
        format.json { render :show, status: :ok, location: @book }
      else
        format.html { render :edit }
        format.json { render json: @book.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /books/1
  # DELETE /books/1.json
  def destroy
    @book.destroy
    respond_to do |format|
      format.html { redirect_to books_url, notice: 'Book was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def favorite
    @book = Book.find(params[:id])
    type = params[:type]
    if type == "favorite"
      current_user.favorites << @book
      redirect_to root_path, notice: "You favorited #{@book.title}"
    elsif type == "unfavorite"
      current_user.favorites.delete(@book)
      redirect_to root_path, notice: "Unfavorited #{@book.title}"
    else
      redirect_to root_path, notice: "All good."
    end
  end

  def purchase
    @book = Book.find_by_isbn(params[:isbn])
    selection = params[:selection]
    if selection == "purchase_more"
      if current_user.selected.detect {|b| b.isbn.to_s == params[:isbn] }.nil?
        current_user.selected << @book
        @notice = "You added  #{@book.title}  to the procurement list"
      else
        @notice = "#{@book.title}  is already on the procurement list"
      end
      redirect_to root_path, notice: "#{@notice}"
    else
      redirect_to root_path, notice: "All good."
    end
  end

  def procurement_list
  end

  def internal
    # @books = Book.all
    # @popularities = Book.popularity
    #
    # #append "future_ranking" to new_books, and sort according to it
    # @new_books = @books.as_json
    # @new_books.each do |obj|
    #   obj["future_ranking"] = (@popularities.detect {|p| p["ISBN"].to_s==obj["isbn"]})["future_ranking"]
    # end
    # @new_books = @new_books.sort_by {|k| k["future_ranking"]}
    #
    # #prepare and format genre list
    # @genre = get_formatted_genre_list(@new_books)
    #
    # #get genre id to display
    # @genre_id = (params[:genre_id].to_i||1).clamp(1, @genre.length)
    # @books_return = filter_book_list_hash(@new_books, @genre, @genre_id)
  end

  def actions
    @book = Book.find_by_isbn(params[:isbn])
    @similarity = Book.similarity_ranking(params[:isbn])
    @similarity = @similarity.detect {|b| b["isbn"].to_s == params[:isbn]} #workaround for Mockaroo bug
    @similarity["similarity_table"] = JSON.load(@similarity["similarity_table"])
  end

  def promote
    if $promotion_list.detect {|b| b["ISBN"]==params["book"]["ISBN"]}.nil?
      $promotion_list<<params[:book]
      @notice = "You added  #{params["book"]["title"]}  to the promotion list"
    else
      @notice = "#{params["book"]["title"]}  is already on the promotion list"
    end
    redirect_to book_actions_path(isbn: params[:isbn]), notice: "#{@notice}"
  end

  def promotion_list
    @isbn = params[:isbn]
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_book
      @book = Book.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def book_params
      params.require(:book).permit(:title, :author)
    end

    #get all the genres, and format it to the format of pull-down selector
    #books in JSON format
    def get_formatted_genre_list(books)
      temp = books.map{|x| x["genre"]}.uniq

      genre = []
      temp.each do |x|
        genre << [x, temp.find_index(x)+1]
      end
      return genre
    end

    def filter_book_list_hash(books, genre, genre_id)
      books.select {|b| b["genre"]==genre[genre_id-1][0]}
    end

    def filter_book_list_activerecord(books, genre, genre_id)
      books.find_all {|b| b.genre == genre[genre_id-1][0]}
    end

    def get_book(books, isbn)
      books.where(isbn:isbn)
    end

    def clear_promotion_list
      $promotion_list = []
    end
end
