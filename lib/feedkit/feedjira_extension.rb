# frozen_string_literal: true

Feedjira::Feed.add_common_feed_element("_feed_id_")
Feedjira::Feed.add_common_feed_entry_element("_public_id_")
Feedjira::Feed.add_common_feed_entry_element("_old_public_id_")
Feedjira::Feed.add_common_feed_entry_element("_data_")
Feedjira::Feed.add_common_feed_entry_element("content")

Feedjira::Parser::Atom.preprocess_xml = true
Feedjira::Parser::AtomFeedBurner.preprocess_xml = true

Feedjira.configure do |config|
  config.logger.level = Logger::ERROR
end

Feedjira.configure do |config|
  config.parsers = config.parsers - [Feedjira::Parser::JSONFeed]
end