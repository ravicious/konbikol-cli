require "test_helper"
require "konbikol/ticket"

class Konbikol::TicketTest < Minitest::Test
  def test_that_ticket_1_is_parsed_correctly
    ticket_text = File.read('test/tickets_for_tests/ticket_1.txt')
    expected_ical = File.read('test/tickets_for_tests/ticket_1.ics')
    actual_ical = Konbikol::Ticket.new(ticket_text).to_ical

    assert_equal sanitize_ical(expected_ical), sanitize_ical(actual_ical)
  end

  def test_that_ticket_2_is_parsed_correctly
    ticket_text = File.read('test/tickets_for_tests/ticket_2.txt')
    expected_ical = File.read('test/tickets_for_tests/ticket_2.ics')
    actual_ical = Konbikol::Ticket.new(ticket_text).to_ical

    assert_equal sanitize_ical(expected_ical), sanitize_ical(actual_ical)
  end

  def test_that_ticket_3_is_parsed_correctly
    ticket_text = File.read('test/tickets_for_tests/ticket_3.txt')
    expected_ical = File.read('test/tickets_for_tests/ticket_3.ics')
    actual_ical = Konbikol::Ticket.new(ticket_text).to_ical

    assert_equal sanitize_ical(expected_ical), sanitize_ical(actual_ical)
  end

  def test_that_ticket_4_is_parsed_correctly
    ticket_text = File.read('test/tickets_for_tests/ticket_4.txt')
    expected_ical = File.read('test/tickets_for_tests/ticket_4.ics')
    actual_ical = Konbikol::Ticket.new(ticket_text).to_ical

    assert_equal sanitize_ical(expected_ical), sanitize_ical(actual_ical)
  end

  private

  DYNAMIC_LINES = %w(DTSTAMP UID)

  # Some lines in the ICS file are different each time you generate an event with icalendar.
  def sanitize_ical(ical)
    ical.lines
      .reject { |line| DYNAMIC_LINES.any? { |prefix| line.start_with?(prefix) } }
      .join('')
  end
end
