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
      departure_line[2]
    end

    # The format is `dd.mm` E.g. `23.04`.
    def departure_date
      departure_line[1]
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
      departure_line[0]
    end

    def arrival_time
      arrival_line[2]
    end

    def arrival_date
      arrival_line[1]
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
      arrival_line[0]
    end

    def carriage
      arrival_line[3]
    end

    def seat
      departure_line[5]
    end

    def train
      departure_line[3]
    end

    def purchase_time
      @purchase_time ||= Time.parse(
        ticket_text.lines[35].split(/\s{2,}/).last.match(/(.+)\(.+/)[1]
      )
    end

    private

    attr_reader :ticket_text

    def departure_line
      @departure_line ||= ticket_text.lines[departure_line_index].split(/\s{2,}/)
    end

    def arrival_line
      @arrival_line ||= ticket_text.lines[departure_line_index + 1].split(/\s{2,}/)
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
