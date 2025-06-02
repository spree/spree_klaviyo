# Klaviyo integration for Spree Commerce

This is an official Klaviyo email marketing extension for [Spree Commerce](https://spreecommerce.org) - the [open-source eCommerce platform](https://spreecommerce.org) for [Rails](https://spreecommerce.org/category/ruby-on-rails/). 

# Event Tracking

Once the [Spree and Klaviyo integration is set up](https://spreecommerce.org/docs/integrations/marketing/klaviyo), Spree automatically tracks the following customer events happening on your store website and sends them to Klaviyo, so you could set up your desired email campaigns triggered by these events:
- Product view
- Product list view
- Product search
- Product added to cart
- Product removed from cart
- Checkout step view
- Checkout step complete
- Coupon entered/removed
- Coupon applied/denied
- Checkout email entered
- Newsletter subscription
- Unsubscribe from newsletter

> [!NOTE]
> When a user subscribes to the newsletter on the storefront, they’re automatically added to the list you configured in the integration settings.

These events populate the Audience → Profiles section in Klaviyo, where you can view each user’s tracked activity and properties. Lists used for newsletter subscriptions can be found in Audience → Lists & Segments.

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


## Join the Community 

[Join our Slack](https://slack.spreecommerce.org) to meet other 6k+ community members and get some support.

## Need more support?

[Contact us](https://spreecommerce.org/contact/) for enterprise support and custom development services. We offer:
  * migrations and upgrades,
  * delivering your Spree application,
  * optimizing your Spree stack.

