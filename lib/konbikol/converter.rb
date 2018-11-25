require 'pdf-reader'
require_relative 'ticket'

module Konbikol
  class Converter
    def convert_ticket_to_event(ticket_file)
      reader = PDF::Reader.new(ticket_file)
      ticket_text = reader.pages.first.text
      Ticket.new(ticket_text)
    end
  end
end
