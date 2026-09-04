# PassKit Ruby gRPC quickstart
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Ruby](https://img.shields.io/badge/Ruby-3.2%2B-CC342D?logo=ruby)

Connect a Ruby application to PassKit and access the Membership, Coupon, Event
Ticket, and Flight APIs through reusable pooled clients. The project uses the
official `passkit-ruby-grpc-sdk` version `1.1.162`.

## Before you start

You need Ruby 3.2 or newer, Bundler, a PassKit account, and the three developer
credential files downloaded from the PassKit portal:

- `certificate.pem`
- `key.pem`
- `ca-chain.pem`

The certificate files authenticate your application. They are not Apple Wallet
certificates and must never be committed to Git.

Legacy EC private keys are converted to the PKCS#8 representation in memory for
compatibility with current Ruby gRPC releases. The key file itself is not changed.
If the key is encrypted, set `PASSKIT_KEY_PASSWORD` in your local `.env`; it is
used only to decrypt and normalize the key in memory.

## Setup

1. Install dependencies:

   ```bash
   bundle install
   ```

2. Create your local configuration:

   ```bash
   cp .env.example .env
   ```

3. Put the three credential files in `certs/`, then update `.env` with your
   email address. For flights, also set `PASSKIT_APPLE_CERTIFICATE` to the pass
   type identifier configured in your PassKit account.

4. Check a workflow:

   ```bash
   bundle exec ruby bin/quickstart membership
   bundle exec ruby bin/quickstart coupons
   bundle exec ruby bin/quickstart event-tickets
   bundle exec ruby bin/quickstart flights
   bundle exec ruby bin/quickstart operations
   ```

Each product command validates the required settings, creates the configured
connection pool, runs a guided create/read/update or redeem lifecycle, prints
the issued resource identifier or pass response, and then removes resources
created by that run. Existing carriers or airports are reused and not deleted.
The `operations` command is read-only and lists the entire SDK method surface.

### Included examples

| Workflow | Examples exercised by the one-command run |
| --- | --- |
| Membership | Images and template, program and tier creation, member enrolment, check-in and check-out, earn and burn points, update, get, list, count, event history, and cleanup |
| Coupons | Images and template, campaign and offer creation, coupon issue, update, get, list, count, redeem, void, and cleanup |
| Event tickets | Images and template, production, venue, event and ticket-type creation, ticket issue, update, lookup by ID/ticket number/order number, list, validate, redeem, and cleanup |
| Flights | Images and template, carrier and airport create-or-reuse, flight and designator creation, flight/designator lookup, boarding-pass issue and lookup, and ordered cleanup |

The shared lifecycle, image, template, and cleanup helpers are in
`lib/passkit/workflow.rb`. Each product is kept in its own focused file:

- `lib/passkit/workflows/membership.rb`
- `lib/passkit/workflows/coupons.rb`
- `lib/passkit/workflows/event_tickets.rb`
- `lib/passkit/workflows/flights.rb`

The low-level shared client remains available when you want to run an
individual operation or build a different lifecycle.

## Use the shared API

Every non-deprecated SDK RPC is available. This includes the four quickstart
products plus images, templates, distribution, messages, analytics, raw passes,
scheduling, certificates, users, and integrations:

```ruby
require "passkit"

config = PassKit::Config.load
config.validate!
pool = PassKit::ConnectionPool.new(config)

pool.with do |client|
  request = Io::Id.new(id: "your-program-id")
  program = client.call(:membership, :get_program, request)
  puts program.name
end
```

Run `bundle exec ruby bin/quickstart operations` for the exact method list. The
main service names are `membership`, `coupons`, `event_tickets`, `flights`,
`images`, `templates`, `distribution`, and `messages`. Generated RPC
names use Ruby snake case, such as `create_program`, `list_coupons_by_coupon_campaign`,
`issue_ticket`, and `create_boarding_pass`. Streaming responses can be enumerated
normally:

```ruby
client.call(:membership, :list_programs, Io::Filters.new).each do |program|
  puts program.name
end
```

See the [PassKit API documentation](https://docs.passkit.io/) for the request
fields and workflow requirements.

## Configuration

| Variable | Default | Purpose |
| --- | --- | --- |
| `PASSKIT_CERTIFICATE` | `certs/certificate.pem` | Client certificate path |
| `PASSKIT_KEY` | `certs/key.pem` | Private-key path |
| `PASSKIT_KEY_PASSWORD` | none | Password for an encrypted private key |
| `PASSKIT_CA_CHAIN` | `certs/ca-chain.pem` | CA-chain path |
| `PASSKIT_GRPC_HOST` | `grpc.pub1.passkit.io` | PassKit gRPC host |
| `PASSKIT_GRPC_PORT` | `443` | PassKit gRPC port |
| `PASSKIT_POOL_SIZE` | `4` | Number of reusable clients |
| `PASSKIT_EMAIL` | none | Recipient used by examples |
| `PASSKIT_APPLE_CERTIFICATE` | none | Pass type identifier required for flights |

## Test

Tests do not connect to PassKit or modify your account:

```bash
bundle exec rake test
bundle exec rubocop
```

## Security

`.env`, PEM keys, certificates, editor settings, and local Bundler files are
ignored.

## Help

- [PassKit Help Centre](https://help.passkit.com/)
- [PassKit API documentation](https://docs.passkit.io/)
- [Ruby SDK](https://github.com/PassKit/passkit-ruby-grpc-sdk)

This project is licensed under the MIT License; see [LICENSE](LICENSE).
