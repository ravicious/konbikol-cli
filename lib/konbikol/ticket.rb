require 'time'
require 'tzinfo'
require 'icalendar'
require 'icalendar/tzinfo'
require 'unidecoder'

module Konbikol
  class Ticket
    TIMEZONE_ID = 'Europe/Warsaw'

    def initialize(ticket_text)
      @ticket_text = ticket_text
    end

    def to_ical
      calendar = Icalendar::Calendar.new
      timezone = TZInfo::Timezone.get TIMEZONE_ID
      ical_timezone = timezone.ical_timezone departure_date

      calendar.add_timezone ical_timezone
      # TODO: Add PRODID.
      # TODO: Search for other useful things to set in an ics file.

      calendar.event do |event|
        event.dtstart = Icalendar::Values::DateTime.new departure_datetime, 'tzid' => TIMEZONE_ID
        event.dtend = Icalendar::Values::DateTime.new arrival_datetime, 'tzid' => TIMEZONE_ID
        event.summary = "#{departure_station} → #{arrival_station}"
        event.description = "#{train}\nwagon #{carriage} miejsce #{seat}"
      end

      calendar.to_ical
    end

    def to_filename
      basename = "#{departure_station}-#{arrival_station}__#{Time.now.to_i.to_s(32)}"
        .to_ascii
        .gsub('.', '')
        .gsub(' ', '_')

      "#{basename}.ics"
    end

    def to_formatted_s
      <<~EVENT
        #{departure_station} → #{arrival_station}
        #{departure_datetime} → #{arrival_datetime}
        #{train}
        wagon #{carriage} miejsce #{seat}
      EVENT
    end

    def departure_time
      departure.fetch(:time)
    end

    # The format is `dd.mm` E.g. `23.04`.
    def departure_date
      departure.fetch(:date)
    end

    def departure_datetime
      return @departure_datetime if @departure_datetime

      datetime = Time.parse("#{purchase_time.year}#{departure_date.split('.').reverse.join('')}#{departure_time.sub(':', '')}")

      if datetime < purchase_time
        # Add one year.
        datetime = Time.parse("#{purchase_time.year + 1}#{departure_date.split('.').reverse.join('')}#{departure_time.sub(':', '')}")
      end

      @departure_datetime = datetime
    end

    def departure_station
      departure.fetch(:station)
    end

    def arrival_time
      arrival.fetch(:time)
    end

    def arrival_date
      arrival.fetch(:date)
    end

    def arrival_datetime
      return @arrival_datetime if @arrival_datetime

      datetime = Time.parse("#{departure_datetime.year}#{arrival_date.split('.').reverse.join('')}#{arrival_time.sub(':', '')}")

      if departure_datetime > datetime
        # Add one year.
        datetime = Time.parse("#{departure_datetime.year + 1}#{arrival_date.split('.').reverse.join('')}#{arrival_time.sub(':', '')}")
      end

      @arrival_datetime = datetime
    end

    def arrival_station
      arrival.fetch(:station)
    end

    def carriage
      arrival.fetch(:carriage)
    end

    def seat
      departure.fetch(:seat)
    end

    def train
      departure.fetch(:train)
    end

    def purchase_time
      return @purchase_time if @purchase_time

      line = find_next_non_empty_line_below_line_matching_regex(/Zapłacono i wystawiono dnia/)

      @purchase_time ||= Time.parse(
        line.split(/\s{2,}/).last.match(/(.+)\(.+/)[1]
      )
    end

    private

    attr_reader :ticket_text

    STATION_AND_REST_REGEX = /^(?<station>\D+(\b|\.))\s+(?<rest>\d.+)$/

    def departure
      return @departure if @departure

      departure_line = ticket_text.lines[departure_line_index]

      match_result = departure_line.match(STATION_AND_REST_REGEX)
      unless match_result
        raise "Departure line didn't match the regex to detect the station and the rest of columns, " \
          "here's how the line looks like:\n\n#{departure_line}"
      end

      station = match_result[:station]
      rest = match_result[:rest]

      rest_columns = rest.split(/\s{2,}/)

      raw_train = rest_columns[2]
      train = raw_train.split(' ').first(2).join(' ')

      # If everything's fine, the departure line should look somewhat like this:
      #
      #     Foo                22.12  13:08   TLK 1111  123   25 o              48,00 zł
      #
      # But sometimes the train ID is too long and there's just one space between the train column
      # and the distance column:
      #
      #     Foo                22.12  13:08   TLK 11111 123   25 o              48,00 zł
      #                                                ^ here
      #
      # This causes troubles for us because we assume that there are at least two spaces between
      # columns, so we have to accommodate for that.
      is_there_just_one_space_between_train_and_distance = raw_train.split(' ').size != 2
      seat = is_there_just_one_space_between_train_and_distance ? rest_columns[3] : rest_columns[4]

      @departure = {
        station: station,
        date: rest_columns[0],
        time: rest_columns[1],
        train: train,
        seat: seat,
      }
    end

    def arrival
      return @arrival if @arrival

      arrival_line = ticket_text.lines[departure_line_index + 1]
      match_result = arrival_line.match(STATION_AND_REST_REGEX)
      unless match_result
        raise "Arrival line didn't match the regex to detect the station and the rest of columns, " \
          "here's how the line looks like:\n\n#{arrival_line}"
      end

      station = match_result[:station]
      rest = match_result[:rest]

      rest_columns = rest.split(/\s{2,}/)

      @arrival = {
        station: station,
        date: rest_columns[0],
        time: rest_columns[1],
        carriage: rest_columns[2],
      }
    end

    def departure_line_index
      @departure_line_index ||= find_index_of_next_non_empty_line_below_line_matching_regex(/Stacja\s+Data\s+Godzina/)
    end

    def find_index_of_next_non_empty_line_below_line_matching_regex(regex)
      lines_with_index = ticket_text.lines.each_with_index
      index_of_line_matching_regex = lines_with_index.find { |line, _| line =~ regex }.last

      # Find the next line after the matching line that's not empty.
      lines_with_index.to_a
        .slice(index_of_line_matching_regex + 1, lines_with_index.size)
        .find { |line, _| !line.strip.empty? }
        .last
    end

    def find_next_non_empty_line_below_line_matching_regex(regex)
      index = find_index_of_next_non_empty_line_below_line_matching_regex(regex)
      ticket_text.lines[index]
    end
  end
end
