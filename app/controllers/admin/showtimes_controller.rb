# frozen_string_literal: true

module Admin
  class ShowtimesController < ApplicationController
    before_action :authenticate_user!
    before_action :find_movie, only: %i[index new create destroy]
    before_action :find_theater, only: %i[new]
    before_action :find_showtime, only: %i[destroy edit update]

    def index
      @movie_theaters = @movie.movie_theater.where(movie_id: params[:movie_id])
      @showtimes = @movie.showtimes.order(cinema_id: :desc)
    end

    def new
      @showtime = Showtime.new
      @cinemas = Cinema.select('name', 'id').map { |cinema| [cinema.name, cinema.id] }
    end

    def create
      @showtimes = @movie.showtimes.all
      @showtime = @movie.showtimes.new(showtime_params)

      showtime_start = showtime_params[:started_at].to_datetime.to_i
      showtime_end = showtime_params[:end_at].to_datetime.to_i

      showtime_all = @showtimes.map {|showtime| [showtime.started_at.to_i, showtime.end_at.to_i]}
      current_time = Time.current.to_i
      showtime_condition = showtime_all.map do |arr|
        if showtime_start < arr[0]
          showtime_end < arr[0]
        elsif showtime_start > arr[1]
          showtime_end > arr[1]
        else
          false
        end
      end

      if not showtime_condition.include?(false) || showtime_start > showtime_end || showtime_start < current_time || showtime_start == showtime_end
        @showtime.save
        redirect_to admin_movie_showtimes_path(@movie.id), notice:"場次新增成功"
      else
        redirect_to admin_movie_showtimes_path(@movie.id), alert:"場次設定有誤,請重新輸入"
      end
    end

    def destroy
      @showtime.destroy
      redirect_to admin_movie_showtimes_path(@movie.id), notice: '刪除場次成功'
    end

    private

    def find_movie
      @movie = Movie.find(params[:movie_id])
    end

    def find_theater
      @theaters = @movie.movie_theater.where(movie_id: params[:movie_id]).map do |cinema|
        [cinema.theater.name, cinema.theater_id]
      end
    end

    def find_showtime
      @showtime = Showtime.find(params[:id])
    end

    def showtime_params
      params.require(:showtime).permit(:started_at, :end_at, :deleted_at, :cinema_id)
    end
  end
end
