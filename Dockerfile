FROM elixir

# install mix and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# configure work directory
WORKDIR /code

# install dependencies
#COPY mix.* /code/
#COPY config /code/ 
COPY . /code/
RUN MIX_ENV=prod mix do deps.get, deps.compile, compile, release

#CMD /bin/bash
ENTRYPOINT /code/rel/tenrest/bin/tenrest foreground
