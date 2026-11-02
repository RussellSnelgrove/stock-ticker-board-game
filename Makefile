.PHONY: up down clean setup logs console test

# The app container's DATABASE_URL points at the development database. Rails applies
# DATABASE_URL to whichever environment runs, so tests must override it or they load
# fixtures into (and delete rows from) the development database.
TEST_DATABASE_URL = postgres://user:password@postgres:5432/stock_ticker_test

up:
	colima start --cpu 4 --memory 6 --vm-type vz --vz-rosetta
	docker-compose up --build

up-detached:
	colima start --cpu 4 --memory 6 --vm-type vz --vz-rosetta
	docker-compose up --build -d

down:
	docker-compose down

clean:
	docker-compose down -v --remove-orphans
	colima stop

setup:
	docker-compose exec app bin/docker-setup

logs:
	docker-compose logs -f app

console:
	docker-compose exec app bin/rails console

test:
	docker-compose exec -e RAILS_ENV=test -e DATABASE_URL=$(TEST_DATABASE_URL) app bin/rails db:test:prepare test
