# Spree Klaviyo

This is an official Klaviyo email marketing extension for [Spree Commerce](https://spreecommerce.org).

## Installation

1. Add this extension to your Gemfile with this line:

    ```ruby
    bundle add spree_klaviyo
    ```

2. Run the install generator

    ```ruby
    bundle exec rails g spree_klaviyo:install
    ```

3. Restart your server

  If your server was running, restart it so that it can find the assets properly.

## Setup guide

[Please follow our setup guide](https://spreecommerce.org/docs/integrations/marketing/klaviyo) how to setup Klaviyo with Spree Commerce.

## Developing

1. Create a dummy app

    ```bash
    bundle update
    bundle exec rake test_app
    ```

2. Add your new code
3. Run tests

    ```bash
    bundle exec rspec
    ```

When testing your applications integration with this extension you may use it's factories.
Simply add this require statement to your spec_helper:

```ruby
require 'spree_klaviyo/factories'
```

## Releasing a new version

```shell
bundle exec gem bump -p -t
bundle exec gem release
```

For more options please see [gem-release README](https://github.com/svenfuchs/gem-release)

## Contributing

If you'd like to contribute, please take a look at the
[instructions](CONTRIBUTING.md) for installing dependencies and crafting a good
pull request.

Copyright (c) 2025 [Vendo Connect Inc.](https://getvendo.com), released under the AGPL 3.0 license.
