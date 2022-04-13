class Metacritic

  def self.last_page(document)
    last_page_link_txt = document.css('li.page.last_page > a').text.strip
    last_page_link_txt.to_i
  end

  def self.list_details(document)
    rows = document.css('table.clamp-list tr')
    rows.map do |row|
      a = row.css('td.details a').first
      link = "https://www.metacritic.com" + a['href']
      title = a.css('h3').text.strip
      platform = row.css('div.platform .data').text.strip
      date = row.css('td.details > span').text.strip
      [link, title, platform, date]
    end
  end

  def self.game_details(document)
    pub_links = document.css('li.summary_detail.publisher > span.data > a')
    pub_details = pub_links.map do |pub_a|
      pub_url = "https://www.metacritic.com" + pub_a.attribute('href')
      pub_name = pub_a.text.strip
      "#{pub_name}|#{pub_url}"
    end

    dev_links = document.css('li.summary_detail.developer > span.data > a')
    dev_details = dev_links.map do |dev_a|
      dev_url = "https://www.metacritic.com" + dev_a.attribute('href')
      dev_name = dev_a.text.strip
      "#{dev_name}|#{dev_url}"
    end
    
    gen_spans = document.css('li.summary_detail.product_genre > span.data')
    genres = gen_spans.map do |gen_span|
      genre = gen_span.text.strip
      "#{genre}"
    end
    
    rating_span = document.css('li.summary_detail.product_rating > span.data')
    rating = rating_span.first&.text&.strip
    [pub_details.join(","), dev_details.join(","), genres.join(","), rating]
  end
end