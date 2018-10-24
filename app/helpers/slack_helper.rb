require 'httparty'

module SlackHelper

  class HangmanHelper

    def initialize(entry,slack_id,slack_name,response_url)
      @entry = entry
      @slack_id = slack_id
      @slack_name = slack_name
      @response_url = response_url
    end

    @game_status = nil
    @game_result = nil

    def create_game
      create_game_url = "https://hangman-rails.herokuapp.com/games"
      backend_response = HTTParty.post(create_game_url, 
        body: {"slack_id"=>"#{@slack_id}", "game_name"=>"#{@entry}", "response_url"=>"#{@response_url}" }.to_json,
        headers: {"Content-Type" => "application/json"}
      )
      @game_id = backend_response["game_id"]
      @game_name = @entry
    end

    def create_player
      create_player_url = "https://hangman-rails.herokuapp.com/players"
      backend_response = HTTParty.post(create_player_url, 
        body: {"slack_id"=>"#{@slack_id}", "slack_name"=>"#{@slack_name}", "game_id"=>"#{@game_id}", "response_url"=>"#{@response_url}" }.to_json,
        headers: {"Content-Type" => "application/json"}
      )
      @player_id = backend_response["player_id"]
    end

    def create_guess
      create_guess_url = "https://hangman-rails.herokuapp.com/guesses"
      backend_response = HTTParty.post(create_guess_url, 
        body: { "game_id"=>"#{@game_id}", "guess"=>"#{@entry}" }.to_json,
        headers: {"Content-Type" => "application/json"}
      )
      @guess_message = backend_response["guess_message"]
      @lives = backend_response["lives"]
      @word_display = backend_response["word_display"]
      @guessed_letters_display = backend_response["guessed_letters_display"]
    end

    def game_exists?
      game_exists_response = HTTParty.get("https://hangman-rails.herokuapp.com/games/exists/#{@game_name || @entry}")
      @game_id = game_exists_response["game_id"]
      @game_exists = game_exists_response["game_exists"]
      @game_status = game_exists_response["game_status"]
      @game_result = game_exists_response["game_result"]
      @game_word = game_exists_response["game_word"]
      @game_exists == 'true' ? true : false
    end

    def game_in_play?
      @game_status == "1" ? true : false
    end

    def game_won?
      @game_result == "1" ? true : false
    end

    def create_game_over_message
      image = game_won? ? "" : get_hangman_url(0)
      status = game_won? ? 'won' : 'lost'
      @game_over_message = { 
        text: "#{@slack_name}", 
        response_type: "ephemeral", 
        attachments: [ 
          {
            "title": "This game was #{status}. The word was #{@game_word}",
            "image_url": "#{image}",
          }   
        ] 
      }
    end

    def post_game_over_message
      create_game_over_message
      HTTParty.post(@response_url, 
        {
          body: @game_over_message.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        }
      )
    end

    def player_exists?
      player_exists_response = HTTParty.get("https://hangman-rails.herokuapp.com/players/exists/#{@slack_id}")
      @player_id = player_exists_response["player_id"]
      @player_exists = player_exists_response["player_exists"]
      @player_exists == 'true' ? true : false
    end

    def guess_exists?
      guess_exists_response = HTTParty.get("https://hangman-rails.herokuapp.com/guesses/exists/#{@slack_id}/#{@entry}")
      @guess_exists = guess_exists_response["guess_exists"]
      @game_name = guess_exists_response["game_name"]
      @guess_exists == 'true' ? true : false
    end

    def update_players_active_game
      update_player_url = "https://hangman-rails.herokuapp.com/players/#{@player_id}"
      HTTParty.put(update_player_url, 
        body: {"slack_id"=>"#{@slack_id}", "slack_name"=>"#{@slack_name}", "game_id"=>"#{@game_id}", "response_url"=>"#{@response_url}" }.to_json,
        headers: {"Content-Type" => "application/json"}
      )
    end

    def post_to_slack(message)
      HTTParty.post(@response_url, 
        {
          body: {"text" => "#{message}", "response_type" => "in_channel"}.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        }
      )
    end

    def post_guess_response_to_slack
      create_guess_message
      HTTParty.post(@response_url, 
        {
          body: @message.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        }
      )
    end

    def create_guess_message
      guesses = @guessed_letters_display ? "Guessed Letters: #{@guessed_letters_display}" : ""
      @message = { 
        text: "#{@slack_name}", 
        response_type: "in_channel", 
        attachments: [ 
          {
            "title": "#{@word_display}",
            "image_url": "#{get_hangman_url(@lives.to_i)}",
            "text": "#{guesses}",
            "fields": [
              {
                "title": "#{@guess_message.downcase.capitalize}",
                "value": "",
                "short": false
              }
            ]
          }   
        ] 
      }
    end

    def get_hangman_url(n)
      [
        "https://hangman-rails.herokuapp.com/assets/0-b750a79d1ba430e02b8f9d91a0acf2756dbb172a599f7f7a30ddfb16407d0cd6.jpg",
        "https://hangman-rails.herokuapp.com/assets/1-81f2ae629bdbbfd515480419e089de6aa169be56966b0acd8b552631335e1978.jpg",
        "https://hangman-rails.herokuapp.com/assets/2-b30c39df5cb6a82511a7341cddba6cbade8306f88c6af625975124887fdfb2e0.jpg",
        "https://hangman-rails.herokuapp.com/assets/3-e8ab6e5dc52c071d50a734ca5eb3b152e405d1e571f123d8faa81ae203d6741d.jpg",
        "https://hangman-rails.herokuapp.com/assets/4-fd2094a2e36842d772b3d38ae805a56adb398c2695f9848d5dc193eebc828efe.jpg",
        "https://hangman-rails.herokuapp.com/assets/5-8d670615e57d7be3890d10523f27f5eff6671e9af349451bf303d87255838616.jpg",
        "https://hangman-rails.herokuapp.com/assets/6-5bc14aa28c5bea4d3aba5e037233f1786676e193d3186eff5b95ab0adcf7801a.jpg",
        "https://hangman-rails.herokuapp.com/assets/7-f5795929d0e3e19a497f412b4dc205b150e9c8501f011e73a24b594d37dcc518.jpg",
        "https://hangman-rails.herokuapp.com/assets/8-1aa61a9e3b612c46f30b6a2122de53b653f56e62d19aa70b0bab62c274882836.jpg",
        "https://hangman-rails.herokuapp.com/assets/9-aabb801a34c0fade0eccd50a9a937c82b5bd8d7cb7bf71827f84ca034f476251.jpg",
        "https://hangman-rails.herokuapp.com/assets/10-c93aeec65266893174082c73bbe885f0b6f676a85ca739cbe52c1848b1aa8b6c.jpg",
        "https://hangman-rails.herokuapp.com/assets/11-2046b079225138643e23b48307801151dad7bae0cc152471e50f7807278c0128.jpg",
        "https://hangman-rails.herokuapp.com/assets/12-678ab4d7564d977561071cf7edf03ba1297140c87a71e3480eb61a23ad8903e1.jpg",
        "https://hangman-rails.herokuapp.com/assets/13-62fa638acb2ba7748be8f28ac724f1856ac4b8a7672d96fad6ec4f6516bceebe.jpg"
      ][n]
    end

  end

  def generate_hangman_helper(entry,slack_id,slack_name,response_url)
    HangmanHelper.new(entry,slack_id,slack_name,response_url)
  end
end
