all: build deploy
.PHONY: build deploy

build:
	bundle exec middleman build --verbose
deploy:
	rsync --delete -avzP build/. web-server@vlang.org:systemverilog.net/.
