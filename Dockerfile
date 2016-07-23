FROM elixir

# install mix and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# configure work directory
WORKDIR /code

# install dependencies
COPY mix.* /code/
COPY config /code/ 
RUN mix do deps.get, deps.compile

CMD /bin/bash
