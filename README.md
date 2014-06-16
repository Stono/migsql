# migsql 
migsql is a simple, lightweight up/down sql migration manager.

Features:
  - Store migrations with unix time stamps, to ensure they're applied sequentially, even if multiple people are working on the same project.
  - Enable both up and down migrations.
  - Store the "state" of the database (ie its current migration) in a migration table on the server itself.
  - Support multiple database confgurations per project.
  - Be a globally accessible binary executable, installed via gem for ease of use.
  - Supports both linux and windows

## Outstanding Work
NOTE: migsql is still under development, in need of a nice 'Green Refactor'.

Still to be done:
  - Configuration file to override defaults (such as ./db location)
  - Apply migrations in a transactional manner, rolling back all migrations part of that batch on failure
  - Some sad-path tests + fixes

## Requirements
Linux: You'll need the freedts package + development libraries, so (depending on your distro):
  - yum install freedts
  - yum install freedts-devel

I have also pulled out the tiny_tds requirement (because of Cygwin).
As a result - if you plan to apply the migrations from your machine, you'll need to do `gem install tiny_tds`

## Getting Started
```
gem install migsql
```
From there, create an initial config with:
```
migsql init
```
This will create a ./db/config.yml - you need to edit this with your database parameters

To create a migration do:
```
migsql create-migration <friendly name>
```
You'll then get up/down scripts for this migration created.  Simply stick your SQL in them.

To execute a migration to the most recent one available:
```
migsql migrate
```
Or to migrate to a specific version (up, or down):
```
migsql migrate to <friendlyname>
```
If you want to forcefully apply a particular up/down script (for testing purposes):
```
migsql apply <friendlyname>
```
## Multiple Databases
If your config.yml contains multiple databases, you will need to specify which db you're targeting, like so:
```
migsql create-migration <friendly name> <dbname>
migsql migrate <dbname>
migsql migrate <dbname> to <friendlyname>
migsql apply <friendlyname> to <dbname>
```
## Contributing
This project has been developed using Test Driven Development, with rspec.
Everything is configured to run automatically with Guard.

You'll need to configure spec/spec_helper.rb with the details of a local SQL server, as some of the tests assert on actual sql manipulations.

Further to this, the branching strategy is gitflow (https://github.com/nvie/gitflow), so please ensure you do your work in feature branches first.

In summary:
  - Clone the repo
  - bundle install
  - Create a feature branch
  - Write some tests
  - Write some code
  - Run your tests 
  - Finish your feature branch
  - Submit a pull request to me

## Release History
  - 1.1.4 Big bug fixes
  - 1.1.3 More informative feedback
  - 1.1.2 Enabled connection override by environment variables
  - 1.1.0 Moved TDS requirement to be used when required
  - 1.0.6 Introduced apply
  - 1.0.5 Refactors and code improvements
  - 1.0.4 Updates to gemspec
  - 1.0.3 Readme updates
  - 1.0.2 Small bug fixes
  - 1.0.1 Small bug fixes
  - 1.0.0 Initial Dev Release

## License
Copyright (c) 2014 Karl Stoney  
Licensed under the MIT license.
