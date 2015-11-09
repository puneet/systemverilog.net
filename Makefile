all: build deploy
.PHONY: build deploy

build:
	bundle exec middleman build --verbose
deploy:
	rsync --delete -avzP build/. web-server@vlang.org:systemverilog.net/.
server:
	bundle exec middleman server
update:
	bundle update
	bower update
init:
	bundle install
