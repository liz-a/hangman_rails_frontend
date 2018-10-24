require 'httparty'

class SlackController < ApplicationController
  skip_before_action :verify_authenticity_token

  def get_input

    response_url = params["response_url"]
    slack_id = params["user_id"]
    slack_name = params["user_name"]
    text = params["text"].split(" ")
    command = text.shift
    entry = text.join(" ").upcase
    
    _ = helpers.generate_hangman_helper(entry,slack_id,slack_name,response_url)

    case command
    when "new"

      if _.game_exists?
        _.post_to_slack("Ooops.. looks like this game already exists! Type `/hangman join #{entry}` to join this game or create one with a different name..")
      else
        _.create_game
        if _.player_exists?
          _.update_players_active_game
        else
          _.create_player
        end
        _.post_to_slack("A new game called #{entry} was created! Type `/hangman guess ` followed by any character to start guessing.  \nOther players can join this game by typing `/hangman join #{entry}`")
      end

    when "join"

      if _.game_exists?
        if _.player_exists?
          _.update_players_active_game
        else
          _.create_player
        end
        _.post_to_slack("You just joined a game called #{entry}..")
        #show game state image etc
      else
        _.post_to_slack("Ooops.. looks like this game doesn't exist! Check for typos and try again..")
      end

    when "guess"
      if _.guess_exists? && _.game_exists? && !_.game_in_play?
        _.post_game_over_message
      elsif !_.guess_exists? && _.game_exists? && !_.game_in_play?
        _.post_game_over_message
      elsif _.guess_exists? && _.game_exists? 
        _.post_to_slack("Looks like you've already played that letter..")
      elsif !_.guess_exists? && _.game_exists? 
        _.create_guess
        _.post_guess_response_to_slack
      else
        _.post_to_slack("Ooops.. looks like the game you're guessing on doesn't exist")
      end

    end

  end
  
end