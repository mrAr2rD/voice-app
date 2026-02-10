class ProjectsController < ApplicationController
  layout "dashboard"
  before_action :require_login
  before_action :set_project, only: %i[show edit update destroy]

  def index
    @projects = current_user.projects.recent
  end

  def show
    @transcriptions = @project.transcriptions.recent.limit(10)
    @translations = @project.translations.recent.limit(10)
    @voice_generations = @project.voice_generations.recent.limit(10)
    @video_builders = @project.video_builders.recent.limit(10)
  end

  def new
    @project = current_user.projects.build
  end

  def create
    @project = current_user.projects.build(project_params)

    if @project.save
      flash[:notice] = "Проект создан"
      redirect_to @project
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      flash[:notice] = "Проект обновлён"
      redirect_to @project
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    flash[:notice] = "Проект удалён"
    redirect_to projects_path
  end

  private

  def set_project
    @project = current_user.projects.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description, :color)
  end
end
