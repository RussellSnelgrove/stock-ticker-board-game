.PHONY: up down clean setup logs console test

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
	docker-compose exec app bin/rails test
