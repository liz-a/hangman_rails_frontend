require 'httparty'

class SlackController < ApplicationController
  skip_before_action :verify_authenticity_token

  def get_input


    response_url = params["response_url"]
    
    response = HTTParty.post(response_url, 
    body: {"text" => "Hello, World FE!", "response_type" => "in_channel"}.to_json,
    headers: {
      "Content-Type" => "application/json"
    }
    )
    
    slack_id = params["user_id"]
    slack_name = params["user_name"]
    text = params["text"].split(" ")
    command = text.shift
    entry = text.join(" ")

    case command
    when "new"
      create_game_url = "https://hangman-rails.herokuapp.com/games"
      backend_response = HTTParty.post(create_game_url, 
        body: {"slack_id"=>"#{slack_id}", "game_name"=>"#{entry}", "response_url"=>"#{response_url}" }.to_json,
        headers: {"Content-Type" => "application/json"}
      )

      Rails.logger.info 'R' * 100
      Rails.logger.info backend_response.inspect
      Rails.logger.info backend_response["game_id"].inspect
      Rails.logger.info backend_response["player"].inspect
      Rails.logger.info 'R' * 100

      game_id = backend_response["game_id"]
      player_exists = backend_response["player"]


      if player_exists == 'true'
        Rails.logger.info "GETTING HERE"

        player_id = backend_response["player_id"]
        update_player_url = "https://hangman-rails.herokuapp.com/players/#{player_id}"
        HTTParty.put(update_player_url, 
        body: {"slack_id"=>"#{slack_id}", "slack_name"=>"#{slack_name}", "game_id"=>"#{game_id}", "response_url"=>"#{response_url}" }.to_json,
        headers: {"Content-Type" => "application/json"}
        )
      else
      create_player_url = "https://hangman-rails.herokuapp.com/players"
      HTTParty.post(create_player_url, 
        body: {"slack_id"=>"#{slack_id}", "slack_name"=>"#{slack_name}", "game_id"=>"#{game_id}", "response_url"=>"#{response_url}" }.to_json,
        headers: {"Content-Type" => "application/json"}
      )
      end

    when "join"
    when "leave"
    when "guess"
    when "score"
    when "leaderboard"
    when "invite"
    when "help"
    end

  end
  
end