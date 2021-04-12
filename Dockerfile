FROM elixir:latest

RUN mkdir /app

RUN apt-get update && \
	apt-get install -y postgresql-client curl inotify-tools apt-utils && \
	curl -sL https://deb.nodesource.com/setup_12.x | bash && \
	apt-get install -y nodejs && \
	mix local.hex --force && \
	mix local.rebar --force

CMD /app/docker_entry.sh
