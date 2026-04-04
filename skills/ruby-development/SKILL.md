---
name: ruby-development
description: >-
  Ruby best practices, patterns, and idioms for building elegant, maintainable
  applications. Use when the task involves `Ruby project`, `Gemfile`, `Ruby on Rails`,
  `RSpec`, or `Ruby gems`.
license: MIT
metadata:
  version: "1.0.0"
---

# Ruby Development

Production patterns and idioms for Ruby programming, covering project structure, gems, blocks,
testing, metaprogramming, and error handling.

## When to Use This Skill

- Starting or structuring a Ruby project
- Working with Bundler and gem dependencies
- Writing idiomatic Ruby with blocks, procs, and lambdas
- Testing with RSpec or Minitest
- Applying Ruby style conventions
- Writing Rake tasks for automation
- Understanding metaprogramming basics

## Core Concepts

### 1. Project Layout

```
myapp/
├── lib/
│   ├── myapp.rb              # Main entry, requires sub-modules
│   └── myapp/
│       ├── client.rb
│       ├── parser.rb
│       └── errors.rb
├── spec/                     # RSpec tests
│   ├── spec_helper.rb
│   ├── myapp/
│   │   ├── client_spec.rb
│   │   └── parser_spec.rb
│   └── support/
│       └── shared_contexts.rb
├── bin/
│   └── myapp                 # CLI executable
├── Gemfile
├── Gemfile.lock
├── Rakefile
├── myapp.gemspec             # If building a gem
└── README.md
```

### 2. Key Principles

| Principle         | Ruby Idiom                                  |
|-------------------|---------------------------------------------|
| Duck typing       | Respond to methods, not check class         |
| Convention        | `snake_case` methods, `PascalCase` classes  |
| Blocks everywhere | Yield to blocks for callbacks and iteration |
| Open classes      | Extend existing classes carefully           |
| POLA              | Principle of Least Astonishment             |

## Quick Start

```bash
# Create a new gem skeleton
bundle gem myapp

# Install dependencies
bundle install

# Run tests
bundle exec rspec
bundle exec rake test   # Minitest

# Run linter
bundle exec rubocop

# Interactive console
bundle exec irb -r ./lib/myapp
```

## Patterns

### Pattern 1: Error Handling

```ruby
module MyApp
  # Define a hierarchy of custom errors
  class Error < StandardError; end
  class NotFoundError < Error; end
  class ValidationError < Error
    attr_reader :field

    def initialize(field, message)
      @field = field
      super("Validation failed on #{field}: #{message}")
    end
  end
  class AuthenticationError < Error; end
end

# Raise and rescue with specificity
class UserService
  def find!(id)
    user = repository.find(id)
    raise MyApp::NotFoundError, "User #{id} not found" unless user
    user
  end

  def create(params)
    validate!(params)
    repository.save(User.new(params))
  rescue MyApp::ValidationError => e
    logger.warn("Validation failed: #{e.message}")
    raise
  rescue StandardError => e
    logger.error("Unexpected error: #{e.message}")
    raise MyApp::Error, "Failed to create user: #{e.message}"
  end

  private

  def validate!(params)
    raise MyApp::ValidationError.new(:email, "is required") if params[:email].nil?
    raise MyApp::ValidationError.new(:email, "is invalid") unless params[:email].match?(URI::MailTo::EMAIL_REGEXP)
  end
end

# Ensure cleanup with ensure
def with_temp_file
  file = Tempfile.new("myapp")
  yield file
ensure
  file&.close
  file&.unlink
end
```

### Pattern 2: Blocks, Procs, and Lambdas

```ruby
# Block — implicit, yielded to
def with_logging(label)
  puts "[START] #{label}"
  result = yield
  puts "[END] #{label}"
  result
end

with_logging("fetch") { http_client.get(url) }

# Proc — stored block, flexible arity
validator = Proc.new { |val| val.is_a?(String) && val.length > 0 }
validator.call("")      # => false
validator.call("hello") # => true

# Lambda — strict arity, returns from lambda only
transform = ->(x) { x.upcase.strip }
names.map(&transform)

# Method objects
processor = method(:process_item)
items.each(&processor)

# Block forwarding with &
def fetch_all(urls, &block)
  urls.map { |url| fetch(url) }.each(&block)
end

fetch_all(urls) { |response| puts response.status }
```

### Pattern 3: Idiomatic Ruby

```ruby
# Guard clauses over nested conditionals
def process(order)
  return unless order.valid?
  return if order.cancelled?

  order.fulfill
end

# Enumerable methods over manual loops
active_users = users.select(&:active?)
emails = active_users.map(&:email)
total = orders.sum(&:total)
grouped = items.group_by(&:category)

# Struct for simple value objects
Coordinate = Struct.new(:lat, :lng, keyword_init: true) do
  def to_s
    "#{lat}, #{lng}"
  end
end

point = Coordinate.new(lat: 40.7, lng: -74.0)

# Frozen string literals (add to top of files)
# frozen_string_literal: true

# Hash and keyword arguments
def create_user(name:, email:, role: :member)
  User.new(name: name, email: email, role: role)
end

# Pattern matching (Ruby 3+)
case response
in { status: 200, body: { data: Array => items } }
  process_items(items)
in { status: 404 }
  handle_not_found
in { status: (500..) }
  handle_server_error
end
```

### Pattern 4: Testing with RSpec

```ruby
# spec/myapp/user_service_spec.rb
require "spec_helper"

RSpec.describe MyApp::UserService do
  subject(:service) { described_class.new(repository: repository) }

  let(:repository) { instance_double(MyApp::UserRepository) }

  describe "#find!" do
    context "when user exists" do
      let(:user) { MyApp::User.new(id: "123", name: "Alice") }

      before do
        allow(repository).to receive(:find).with("123").and_return(user)
      end

      it "returns the user" do
        expect(service.find!("123")).to eq(user)
      end
    end

    context "when user does not exist" do
      before do
        allow(repository).to receive(:find).with("999").and_return(nil)
      end

      it "raises NotFoundError" do
        expect { service.find!("999") }
          .to raise_error(MyApp::NotFoundError, /User 999 not found/)
      end
    end
  end

  describe "#create" do
    let(:valid_params) { { email: "alice@example.com", name: "Alice" } }

    it "saves the user" do
      allow(repository).to receive(:save).and_return(true)

      service.create(valid_params)

      expect(repository).to have_received(:save).with(
        an_instance_of(MyApp::User)
      )
    end

    it "raises on invalid email" do
      expect { service.create(email: nil, name: "Alice") }
        .to raise_error(MyApp::ValidationError)
    end
  end
end
```

### Pattern 5: Metaprogramming (Use Sparingly)

```ruby
module MyApp
  # Dynamic attribute accessors
  module Attributes
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def attribute(name, type: String, default: nil)
        define_method(name) do
          instance_variable_get(:"@#{name}") || default
        end

        define_method(:"#{name}=") do |value|
          unless value.is_a?(type)
            raise TypeError, "Expected #{type}, got #{value.class}"
          end
          instance_variable_set(:"@#{name}", value)
        end
      end
    end
  end

  class Config
    include Attributes

    attribute :host, type: String, default: "localhost"
    attribute :port, type: Integer, default: 3000
    attribute :debug, type: TrueClass, default: false
  end
end

# method_missing — always pair with respond_to_missing?
class FlexibleConfig
  def initialize(data = {})
    @data = data
  end

  def method_missing(name, *args)
    key = name.to_s.chomp("=").to_sym
    if name.to_s.end_with?("=")
      @data[key] = args.first
    elsif @data.key?(key)
      @data[key]
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    @data.key?(name.to_s.chomp("=").to_sym) || super
  end
end
```

### Pattern 6: Rake Tasks

```ruby
# Rakefile
require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

namespace :db do
  desc "Run database migrations"
  task :migrate do
    require_relative "lib/myapp"
    MyApp::Database.migrate!
    puts "Migrations complete"
  end

  desc "Seed the database"
  task seed: :migrate do
    MyApp::Database.seed!
    puts "Seed complete"
  end

  desc "Reset database"
  task reset: [:drop, :migrate, :seed]

  desc "Drop database"
  task :drop do
    MyApp::Database.drop!
    puts "Database dropped"
  end
end
```

## Best Practices

### Do's

- **Use `frozen_string_literal: true`** — Prevents accidental string mutation, improves performance
- **Prefer keyword arguments** — For methods with more than 2 parameters
- **Write guard clauses** — Early returns keep code flat and readable
- **Use `Enumerable` methods** — `map`, `select`, `reduce` over manual loops
- **Pair `method_missing` with `respond_to_missing?`** — Always
- **Freeze constants** — `DEFAULTS = { timeout: 30 }.freeze`
- **Use `bundle exec`** — To ensure correct gem versions

### Don'ts

- **Don't rescue `Exception`** — Catches `SignalException`, `SystemExit`; rescue `StandardError`
  instead
- **Don't monkey-patch in production** — Open classes are powerful but dangerous
- **Don't use `eval` with user input** — Security risk
- **Don't ignore `Rubocop` warnings** — Fix or explicitly disable with comments
- **Don't overuse metaprogramming** — Clever code is hard to debug and maintain
- **Don't mutate method arguments** — Use `.dup` or `.freeze` defensively

## Resources

- [Ruby Style Guide](https://rubystyle.guide/)
- [RSpec Best Practices](https://www.betterspecs.org/)
- [Ruby API Docs](https://ruby-doc.org/)
- [Rubocop](https://docs.rubocop.org/)
