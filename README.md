# migsql 
migsql is a simple, lightweight up/down sql migration manager.
Features:
  - Store migrations with unix time stamps, to ensure they're applied sequentially, even if multiple people are working on the same project.
  - Enable both up and down migrations.
  - Store the "state" of the database (ie its current migration) in a migration table on the server itself.
  - Support multiple database confgurations per project.
  - Be a globally accessible binary executable, installed via gem for ease of use.
  - Currently only supports linux due to the freetds requirement.

## Outstanding Work
NOTE: migsql is still under development, in need of a nice 'Green Refactor'.
Still to be done:
  - Configuration file to override defaults (such as ./db location)
  - Apply migrations in a transactional manner, rolling back all migrations part of that batch on failure
  - Some sad-path tests + fixes
  - Cygwin support for windows developers

## Requirements
You'll need the freedts package + development libraries, so (depending on your distro):
  - yum install freedts
  - yum install freedts-devel

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
To execute a migration do:
```
migsql migrate (this will migrate the database in your config, to the latest available migration)
or
migsql migrate to <friendlyname> (this will migrate the database in your config, to the specified migration)
```
## Multiple Databases
If your config.yml contains multiple databases, you will need to specify which db you're targeting, like so:
```
migsql create-migration <friendly name> <dbname>
migsql migrate <dbname>
migsql migrate <dbname> to <friendlyname>
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
  - 1.0.4 Updates to gemspec
  - 1.0.3 Readme updates
  - 1.0.2 Small bug fixes
  - 1.0.1 Small bug fixes
  - 1.0.0 Initial Dev Release

## License
Copyright (c) 2014 Karl Stoney  
Licensed under the MIT license.
