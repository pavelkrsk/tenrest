# Tenrest

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `tenrest` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:tenrest, "~> 0.1.0"}]
    end
    ```

  2. Ensure `tenrest` is started before your application:

    ```elixir
    def application do
      [applications: [:tenrest]]
    end
    ```

## Running With Docker

1. docker pull elixir
2. docker pull redis
3. docker-compose build
4. docker-compose run -d --service-ports tenrest

### Example requests with CURL

**Read**
```bash
curl -H "Accept-Version:2.0" http://server:8080/kv/foo
```

**Update**
```bash
curl -H "Accept-Version:2.0" http://server:8080/kv/foo -XPUT -d value=bar -d ttl=20
```

**Delete**
```bash
curl -H "Accept-Version:2.0" http://server:8080/kv/foo -XDELETE
```
