

class RoomsController < ApplicationController
  def show
    raise ActionController::RoutingError.new('Source not Found') unless params[:source] == 'guardian'
    raise ActionController::RoutingError.new('Series not Found') unless params[:series].in?(Series::SERIES)
    @crossword = crossword
    puts 'CROSSWORD'
    puts crossword
    @parsed_crossword = JSON.parse(crossword)["data"]
    puts 'PARSED'
    puts @parsed_crossword
    @url = url
  end

  def crossword_identifier
    [params[:source], params[:series], params[:identifier]].join('/')
  end
  helper_method :crossword_identifier

  def crossword
    if redis.exists(crossword_identifier)
      redis.get(crossword_identifier)
    else
      get_crossword_data.tap {|data| redis.set(crossword_identifier, data) }
    end
  end

  def get_crossword_data
    puts url
    response = Faraday.get(url)
    html = Nokogiri::HTML(response.body)
    puts html

    crossword_element = html.css('.js-crossword')

    if crossword_element.any?
      raw_data = crossword_element.first['data-crossword-data']
    else
      island_element = html.css('gu-island[name="CrosswordComponent"]')
      raise ActionController::RoutingError.new('Crossword not found') unless island_element.any?

      props_json = island_element.first['props']
      raw_data = CGI.unescapeHTML(props_json)
    end

    raw_data
  end

  def url
    "https://www.theguardian.com/crosswords/#{params[:series]}/#{params[:identifier]}"
  end

  def redis
    @redis ||= Redis.new
  end
end
