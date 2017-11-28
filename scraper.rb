#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'
require 'wikidata_ids_decorator'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MembersPage < Scraped::HTML
  field :members do
    # TODO
  end

  private

  def table
    noko.xpath(".//table[.//th[contains(.,'Member')]]").first
  end
end

url = 'https://en.wikipedia.org/wiki/Members_of_the_Australian_House_of_Representatives,_2016%E2%80%932019'
page = MembersPage.new(response: Scraped::Request.new(url: url).response)
data = page.members.map(&:to_h)

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
# ScraperWiki.save_sqlite([:name, :wikidata], data)
