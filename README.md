# Konbikol

Converts PKP Intercity PDF train tickets to iCalendar events.

## Installation

```
gem install konbikol
```

## Usage

```
konbikol file.pdf
```

This will try to open file.pdf, convert it to a ticket, then save it to a temporary directory and
then attempt to open that file (given that there's `open` command in your path).

By default on macOS, this will result in Calendar asking you about what calendar you want to add the
event to.  Well, at least that's what happens for me since I have more than one calendar.

## Development

After checking out the repo, run `bundle` to install dependencies. Then, run `rake test` to run the
tests.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new
version, update the version number in `version.rb`, and then run `bundle exec rake release`, which
will create a git tag for the version, push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ravicious/konbikol-cli. This
project is intended to be a safe, welcoming space for collaboration, and contributors are expected
to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the Konbikol project’s codebases, issue trackers, chat rooms and mailing
lists is expected to follow the [code of conduct](https://github.com/ravicious/konbikol-cli/blob/master/CODE_OF_CONDUCT.md).
