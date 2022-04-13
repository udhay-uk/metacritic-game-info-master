# encoding: utf-8

require 'nokogiri'
require 'faraday'
require 'faraday/retry'
require 'limiter'
require 'openssl'

class MasterScrapper

  extend Limiter::Mixin

  limit_method :fetch, rate: 120

  def initialize(logger, cache_loc)
    @cache_loc = cache_loc
    @logger = logger
    @sha = OpenSSL::Digest::MD5.new
    @faraday = Faraday.new do |conn|
      conn.request(:retry, max: 2,
                           interval: 0.05,
                           interval_randomness: 0.5,
                           backoff_factor: 2,
                           exceptions: ['Timeout::Error'])

      conn.adapter(:net_http) # NB: Last middleware must be the adapter
    end
    @counter = 0
  end

  def fetch(name, url, options)
    cache(name, url) do |get_url|
      response = faraday.get(url, options)
      response.body
    end
  end

  private
  def digest(str) sha.hexdigest(str)[0..7]; end

  def cache(name, url)
    filename = name.gsub(/[^A-Za-z0-9]/,"")
    file_path = "#{cache_loc}/#{filename}#{digest(url)}.html"
    content_text = nil
    if(File.exists?(file_path))
      @counter += 1
      logger.info "cache hit! total: #{@counter}" if @counter % 5 == 0
      content_text = File.read(file_path) 
    else
      logger.info "cache miss #{url}"
      content_text = yield(url)
      File.open(file_path, 'w') { |file| file.write(content_text) }
    end
    Nokogiri::HTML(content_text)
  end

  attr_reader :logger, :cache_loc, :sha, :faraday

end