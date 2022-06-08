FROM ruby:3.0-alpine3.16 as ruby-base

# --- Build image
FROM ruby-base AS builder
WORKDIR /app

# bundle install deps
RUN apk add --update ca-certificates git build-base openssl-dev
RUN gem install bundler -v '>= 2'

# bundle install
COPY Gemfile* ./
RUN bundle

# --- Runtime image
FROM ruby-base
WORKDIR /app

COPY --from=builder /usr/local/bundle /usr/local/bundle
RUN apk --update upgrade && apk add --no-cache ca-certificates

COPY . .
RUN addgroup -g 1000 -S app \
  && adduser -u 1000 -S app -G app \
  && chown -R app: .

USER app
STOPSIGNAL INT
ENTRYPOINT ["bundle", "exec", "ruby", "main.rb"]
