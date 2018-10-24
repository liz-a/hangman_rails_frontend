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
    entry = text.join(" ").upcase

    case command
    when "new"

    game_exists_response = HTTParty.get("https://hangman-rails.herokuapp.com/games/exists/#{entry}")

    game_exists = game_exists_response["game_exists"]

    if game_exists == 'false'

      create_game_url = "https://hangman-rails.herokuapp.com/games"
      backend_response = HTTParty.post(create_game_url, 
        body: {"slack_id"=>"#{slack_id}", "game_name"=>"#{entry}", "response_url"=>"#{response_url}" }.to_json,
        headers: {"Content-Type" => "application/json"}
      )

      game_id = backend_response["game_id"]
      player_exists = backend_response["player"]

      if player_exists == 'true'
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

    else

      HTTParty.post(response_url, 
      {
        body: {"text" => "Game exists, type /hangman join #{entry} to join the game or create a game with a different name", "response_type" => "in_channel"}.to_json,
        headers: {
          "Content-Type" => "application/json"
        }
      }
      )

    end

    when "guess"

    guess_exists_response = HTTParty.get("https://hangman-rails.herokuapp.com/guesses/exists/#{slack_id}/#{entry}")

    guess_exists = guess_exists_response["guess_exists"]

    game_id = guess_exists_response["game_id"]

    if guess_exists == 'false'

      create_guess_url = "https://hangman-rails.herokuapp.com/guesses"
      backend_response = HTTParty.post(create_guess_url, 
      body: { "game_id"=>"#{game_id}", "guess"=>"#{entry}" }.to_json,
      headers: {"Content-Type" => "application/json"}
      )

      guess_message = backend_response["guess_message"]
      lives = backend_response["lives"]
      word_display = backend_response["word_display"]
      guessed_letters_display = backend_response["guessed_letters_display"]

      HTTParty.post(response_url, 
      {
        body: {"text" => "#{guess_message}\n#{word_display}\n#{lives}\n#{guessed_letters_display}", "response_type" => "in_channel"}.to_json,
        headers: {
          "Content-Type" => "application/json"
        }
      }
      )

    else
      HTTParty.post(response_url, 
      {
        body: {"text" => "LETTER ALREADY PLAYED", "response_type" => "in_channel"}.to_json,
        headers: {
          "Content-Type" => "application/json"
        }
      }
      )
    end

      # create_guess_url = "https://hangman-rails.herokuapp.com/guess"
      # backend_response = HTTParty.post(create_guess_url, 
      # body: {"slack_id"=>"#{slack_id}", "game_name"=>"#{entry}", "response_url"=>"#{response_url}" }.to_json,
      # headers: {"Content-Type" => "application/json"}
      # )


    when "join"

      game_exists_response = HTTParty.get("https://hangman-rails.herokuapp.com/games/exists/#{entry}")


      Rails.logger.debug "&" * 100
      Rails.logger.debug game_exists_response
      Rails.logger.debug "&" * 100

      game_exists = game_exists_response["game_exists"]

      game_id = game_exists_response["game_id"]

      player_exists_response = HTTParty.get("https://hangman-rails.herokuapp.com/players/exists/#{slack_id}")

      player_exists = player_exists_response["player_exists"]
      player_id = player_exists_response["player_id"]

      if game_exists == 'true'

        if player_exists == 'true'
          #update active game
          update_player_url = "https://hangman-rails.herokuapp.com/players/#{player_id}"
          HTTParty.put(update_player_url, 
          body: {"slack_id"=>"#{slack_id}", "slack_name"=>"#{slack_name}", "game_id"=>"#{game_id}", "response_url"=>"#{response_url}" }.to_json,
          headers: {"Content-Type" => "application/json"}
          )
        else
          #create player
          create_player_url = "https://hangman-rails.herokuapp.com/players"
          HTTParty.post(create_player_url, 
          body: {"slack_id"=>"#{slack_id}", "slack_name"=>"#{slack_name}", "game_id"=>"#{game_id}", "response_url"=>"#{response_url}" }.to_json,
          headers: {"Content-Type" => "application/json"}
          )
        end

      else

        HTTParty.post(response_url, 
        {
          body: {"text" => "GAME DOES NOT EXIST", "response_type" => "in_channel"}.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        }
        )

      end


    when "leave"
    when "score"
    when "leaderboard"
    when "invite"
    when "help"
    end

  end
  
end