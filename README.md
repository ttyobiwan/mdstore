# mdstore

mdstore is an ecommerce app built with Phoenix framework, that focuses on simplicity and markdown-like design.

## Installation

To get started, first prepare an `.env` file with all environment variables:

```
export STRIPE_SECRET=
export STRIPE_PUBLISHABLE_KEY=
export REDIS_HOST=localhost
```

Then, take the following steps to start your Phoenix server:

* Run `docker compose up` to start all extra services in Docker containers
* Run `mix setup` to install and setup dependencies
* Export your env variables, e.g. by using `source .env`
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Next

- [ ] Orders

## Backlog

- [x] Admin users
- [x] Product models
- [x] Admin form for creating products
  - [x] Form tests
  - [x] Auth tests
- [x] Admin view for listing products
  - [x] Pagination
  - [x] Tests
- [x] Updating and deleting products
- [x] Navbar
- [x] Landing page
- [x] Product list view
- [x] Product detail view
- [x] Product pages tests
- [x] Cart
- [x] Cart page
- [x] Cart tests
- [x] Working auth
- [x] Purchase models
- [x] Payments
- [x] Fix theme switch not being a switch
- [x] Cart checkout
- [x] Checkout tests
- [x] Featured products
- [x] Cache featured products

- [ ] 404 page
- [ ] Django-like admin navigation
- [ ] Search in admin

## Future

- [ ] Wishlist
- [ ] Coupons
- [ ] Notifications
- [ ] Oban job to clean up orphaned images

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
