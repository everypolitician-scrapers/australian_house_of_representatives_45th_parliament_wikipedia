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
    member_list.map do |m|
      mem = m.to_h
      mem.merge(party_wikidata: parties_to_wikidata[mem[:party]])
    end
  end

  private

  def parties_to_wikidata
    parties_with_wikidata = member_list.reject { |m| m.party_wikidata.empty? }
    parties_with_wikidata.map { |p| [p.party, p.party_wikidata] }.to_h
  end

  def member_list
    @member_list ||= table.xpath('.//tr[td]').map do |tr|
      fragment tr => MemberRow
    end
  end

  def table
    noko.xpath(".//table[.//th[contains(.,'Member')]]").first
  end
end

class MemberRow < Scraped::HTML
  field :name do
    # Remove footnote link if present
    tds[0].at(:sup)&.remove
    tds[0].text.tidy
  end

  field :wikidata do
    tds[0].css('a/@wikidata').first.text
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

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
ScraperWiki.save_sqlite([:name, :wikidata], page.members)
