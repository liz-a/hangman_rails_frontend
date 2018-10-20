require 'httparty'

class SlackController < ApplicationController
  skip_before_action :verify_authenticity_token

  def get_input
    Rails.logger.info '*' * 100
    Rails.logger.info params.inspect
    Rails.logger.info '*' * 100

    response_url = params["response_url"]
    
    response = HTTParty.post(response_url, 
    body: {"text" => "Hello, World FE!","response_type" => "in_channel"}.to_json,
    headers: {
      "Content-Type" => "application/json"
    }
    )
    
    text = params["text"].split(" ")
    command = text.shift
    entry = text.join(" ")

    case command
    when "new"
      create_game_url = "https://hangman-rails.herokuapp.com/games"
      backend_response = HTTParty.post(create_game_url, 
        body: {"game_name"=>"#{entry}"}.to_json,
        headers: {"Content-Type" => "application/json"}
      )
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