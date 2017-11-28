#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'
require 'wikidata_ids_decorator'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MembersPage < Scraped::HTML
  decorator WikidataIdsDecorator::Links

  field :members do
    table.xpath('.//tr[td]').map do |tr|
      mem = fragment(tr => MemberRow).to_h
      mem.merge(party_wikidata: parties[mem[:party]])
    end
  end

  field :parties do
    mems = table.xpath('.//tr[td]').map do |tr|
      fragment tr => MemberRow
    end
    mems.reject { |m| m.party_wikidata.empty? }.map { |p| [p.party, p.party_wikidata] }.to_h
  end

  private

  def table
    noko.xpath(".//table[.//th[contains(.,'Member')]]").first
  end
end

class MemberRow < Scraped::HTML
  field :name do
    tds[0].text
  end

  field :wikidata do
    tds[0].css('a/@wikidata').text
  end

  field :party do
    # First remove footnote link if present
    tds[1].at(:sup)&.remove
    tds[1].text.tidy
  end

  field :party_wikidata do
    tds[1].css('a/@wikidata').text
  end

  field :electorate do
    tds[2].text
  end

  field :electorate_wikidata do
    tds[2].css('a/@wikidata').text
  end

  field :state do
    tds[3].text
  end

  private

  def tds
    noko.css('td')
  end
end

url = 'https://en.wikipedia.org/wiki/Members_of_the_Australian_House_of_Representatives,_2016%E2%80%932019'
page = MembersPage.new(response: Scraped::Request.new(url: url).response)
data = page.members.map(&:to_h)

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
ScraperWiki.save_sqlite([:name, :wikidata], data)
