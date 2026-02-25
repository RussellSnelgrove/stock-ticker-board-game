# Open Issues

Items that need to be addressed in the documentation before building.

- [ ] **Rails 8.1 Solid gems conflict**: Rails 8.1 ships with `solid_cache`, `solid_queue`, and `solid_cable` gems that try to connect to their own databases and conflict with Redis. The task list MUST explicitly say to remove these gems from the Gemfile, delete their config files (`config/cache.yml`, `config/queue.yml`, `config/recurring.yml`, `db/cache_schema.rb`, `db/queue_schema.rb`, `db/cable_schema.rb`), remove the Solid Queue Puma plugin from `config/puma.rb`, and replace their references in `config/environments/production.rb` with Redis-backed alternatives.
- [x] ~~**importmap bare specifiers**: Added to Task 9 in the task list.~~
- [x] ~~**`.ruby-version` conflicts**: Added `.dockerignore` and delete step to Task 1 in the task list.~~
- [x] ~~**PostgreSQL health check**: Added `-d stock_ticker_development` requirement to Task 1 in the task list.~~
- [ ] **`current_price` stored as integer cents**: The task list says "range $0.00-$2.00" which reads like a decimal. It MUST explicitly state: "stored as integer cents (100 = $1.00, range 0-200)".
- [ ] **Action Cable session access in Docker**: For the WebSocket connection to identify the user from the Rails session cookie, document how `ApplicationCable::Connection` should read `request.session[:user_id]` and that `config.action_cable.disable_request_forgery_protection = true` is needed in development.
- [ ] **`active_player` computation**: Define the formula for determining whose turn it is. Specify: `players.active.order(:turn_position).offset(current_turn % active_player_count).first`. This should be in the Game model section of Task 4.
- [ ] **Invite code format**: Specify "6-character uppercase alphanumeric, generated via `SecureRandom.alphanumeric(6).upcase`".
- [ ] **Duration options**: Specify the exact select options: 15, 30, 60, 90 minutes. State whether free-form input is allowed or only these presets.
- [ ] **Background job adapter**: Specify that Active Job should use the `:async` adapter for development (since Solid Queue is removed). Note this in Task 1 or Task 5.
- [ ] **Tie-breaking at game end**: Define what happens when two players have the same net worth at timer expiry.
- [ ] **UI Spec Screen 3 is stale**: Screen 3 documents the old prototype's local pass-and-play setup screen. Replace it with the username entry form that the app actually uses.
- [ ] **Exact Ruby/Rails versions**: Pin to specific versions (e.g., Ruby 3.3.7, Rails 8.1.2) instead of "3.3.x" and "8.x".
- [ ] **`config.hosts.clear` for network access**: Document that `config.hosts.clear` and `config.action_cable.disable_request_forgery_protection = true` must be set in `config/environments/development.rb` for multiplayer on a local network or via tunnels.
- [ ] **Stock change percentage**: The stock card change percentage should show the change from the **last price movement** (previous roll that affected that stock), NOT the overall change from $1.00. Document this in the UI spec under Stock Board and in the task list under Task 10.
