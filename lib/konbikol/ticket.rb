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
      @purchase_time ||= Time.parse(
        ticket_text.lines[35].split(/\s{2,}/).last.match(/(.+)\(.+/)[1]
      )
    end

    private

    attr_reader :ticket_text

    def departure
      return @departure if @departure
      line = ticket_text.lines[departure_line_index].split(/\s{2,}/)

      raw_train = line[3]
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
      seat = is_there_just_one_space_between_train_and_distance ? line[4] : line[5]

      @departure = {
        station: line[0],
        date: line[1],
        time: line[2],
        train: train,
        seat: seat,
      }
    end

    def arrival
      return @arrival if @arrival

      line = ticket_text.lines[departure_line_index + 1].split(/\s{2,}/)

      @arrival = {
        station: line[0],
        date: line[1],
        time: line[2],
        carriage: line[3],
      }
    end

    def departure_line_index
      return @departure_line_index if @departure_line_index

      lines_with_index = ticket_text.lines.each_with_index
      header_line_index = lines_with_index.find { |line, _| line.start_with?('Stacja             Data Godzina') }.last

      # Find the next line after the header line that's not empty.
      @departure_line_index = lines_with_index.to_a
        .slice(header_line_index + 1, lines_with_index.size)
        .find { |line, _| !line.strip.empty? }
        .last
    end
  end
end
