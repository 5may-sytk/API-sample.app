class TodolistsController < ApplicationController
  def new
    @list = List.new
  end

  def create
    @list = List.new(list_params)
    @list.score = Language.get_data(list_params[:body]) 

    is_safe = Vision.image_analysis(list_params[:image])
    if is_safe
      if @list.save
        redirect_to todolist_path(@list.id)
        tags.each do |tag|
          @list.tags.create(name: tag)
        end
      else
        flash.now[:notice] = "この画像はエラーです"
        render :new
      end
    end
  end

  def index
    @lists = List.all
  end

  def show
    @list = List.find(params[:id])
  end

  def edit
    @list = List.find(params[:id])
  end

  def update
    list = List.find(params[:id])
    list.update(list_params)
    redirect_to todolist_path(list.id)
  end

  def destroy
    list = List.find(params[:id])
    list.destroy
    redirect_to todolists_path
  end

  private

  def list_params
    params.require(:list).permit(:title, :body, :image)
  end

end
