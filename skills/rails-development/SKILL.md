---
name: rails-development
description: >-
  Ruby on Rails best practices and conventions covering MVC patterns, ActiveRecord,
  RESTful routing, testing with RSpec, background jobs, and production-ready Rails
  development. Use when the task involves `Ruby on Rails`, `Rails project`,
  `ActiveRecord`, `Rails migrations`, or `Rails API`.
license: MIT
metadata:
  version: "1.0.0"
---

## When to Use

- Building or refactoring a Ruby on Rails application.
- Writing ActiveRecord models with validations, associations, and scopes.
- Setting up RESTful routes and controllers following Rails conventions.
- Writing tests with RSpec and FactoryBot.
- Configuring background jobs with Sidekiq or ActiveJob.
- Optimizing database queries to prevent N+1 problems.

## Critical Patterns

- **Convention Over Configuration:** Follow Rails naming conventions strictly. Model `User` maps to
  table `users`, controller `UsersController` in `users_controller.rb`. Fighting conventions creates
  maintenance nightmares.
- **Fat Model, Skinny Controller:** Controllers handle HTTP flow only — delegate business logic to
  models, service objects, or concerns.
- **Prevent N+1 Queries:** ALWAYS use `includes`, `preload`, or `eager_load` when accessing
  associations in collections. Use `bullet` gem in development to detect violations.
- **Strong Parameters:** NEVER trust user input. Whitelist permitted params in every controller
  action.
- **Database-Level Constraints:** Add validations in the model AND enforce them at the database
  level with migration constraints (`null: false`, unique indexes, foreign keys).
- **Background Jobs for Slow Work:** Anything over 100ms that isn't the core response (emails, file
  processing, API calls) goes into a background job.

## Code Examples

### Model with Validations and Associations

```ruby
# app/models/user.rb
class User < ApplicationRecord
  # Associations
  has_many :posts, dependent: :destroy
  has_many :comments, through: :posts
  has_one :profile, dependent: :destroy
  belongs_to :organization, optional: true

  # Validations — always mirror with DB constraints
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :role, inclusion: { in: %w[user admin moderator] }

  # Scopes — chainable, reusable query fragments
  scope :active, -> { where(deactivated_at: nil) }
  scope :admins, -> { where(role: "admin") }
  scope :created_after, ->(date) { where("created_at > ?", date) }
  scope :search, ->(query) {
    where("name ILIKE :q OR email ILIKE :q", q: "%#{sanitize_sql_like(query)}%")
  }

  # Callbacks — use sparingly
  before_save :normalize_email

  private

  def normalize_email
    self.email = email.downcase.strip
  end
end
```

### Migration with Proper Constraints

```ruby
class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :role, null: false, default: "user"
      t.references :organization, foreign_key: true
      t.datetime :deactivated_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :role
    add_index :users, :deactivated_at
  end
end
```

### Controller with Strong Parameters

```ruby
# app/controllers/api/v1/users_controller.rb
module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user!
      before_action :set_user, only: %i[show update destroy]
      before_action :authorize_admin!, only: %i[destroy]

      # GET /api/v1/users
      def index
        @users = User.active
                     .includes(:organization, :profile)
                     .order(created_at: :desc)
                     .page(params[:page])

        render json: @users, each_serializer: UserSerializer
      end

      # GET /api/v1/users/:id
      def show
        render json: @user, serializer: UserDetailSerializer
      end

      # POST /api/v1/users
      def create
        @user = User.new(user_params)

        if @user.save
          UserMailer.welcome_email(@user).deliver_later
          render json: @user, status: :created
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/users/:id
      def update
        if @user.update(user_params)
          render json: @user
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_user
        @user = User.find(params[:id])
      end

      def user_params
        params.require(:user).permit(:name, :email, :role, :organization_id)
      end
    end
  end
end
```

### RESTful Routing

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users, only: %i[index show create update destroy] do
        member do
          patch :deactivate
        end
        collection do
          get :search
        end
      end

      resources :posts do
        resources :comments, only: %i[index create destroy], shallow: true
      end
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
```

### Preventing N+1 Queries

```ruby
# BAD — triggers N+1
users = User.all
users.each { |u| puts u.posts.count }

# GOOD — eager loads associations
users = User.includes(:posts).all
users.each { |u| puts u.posts.size }  # .size uses preloaded data

# GOOD — when you only need counts
users = User.left_joins(:posts)
             .select("users.*, COUNT(posts.id) AS posts_count")
             .group("users.id")

# GOOD — counter cache for frequent counts
# Migration: add_column :users, :posts_count, :integer, default: 0
class Post < ApplicationRecord
  belongs_to :user, counter_cache: true
end
```

### Service Object Pattern

```ruby
# app/services/users/create_service.rb
module Users
  class CreateService
    def initialize(params:, current_user:)
      @params = params
      @current_user = current_user
    end

    def call
      user = User.new(@params)

      ActiveRecord::Base.transaction do
        user.save!
        user.create_profile!
        AuditLog.record!(action: "user.created", actor: @current_user, target: user)
      end

      UserMailer.welcome_email(user).deliver_later
      ServiceResult.new(success: true, data: user)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.new(success: false, errors: e.record.errors.full_messages)
    end
  end
end
```

### RSpec Tests

```ruby
# spec/models/user_spec.rb
RSpec.describe User, type: :model do
  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "associations" do
    it { is_expected.to have_many(:posts).dependent(:destroy) }
    it { is_expected.to belong_to(:organization).optional }
  end

  describe ".active" do
    it "excludes deactivated users" do
      active_user = create(:user, deactivated_at: nil)
      create(:user, deactivated_at: 1.day.ago)

      expect(User.active).to eq([active_user])
    end
  end
end

# spec/requests/api/v1/users_spec.rb
RSpec.describe "Api::V1::Users", type: :request do
  let(:admin) { create(:user, role: "admin") }
  let(:headers) { auth_headers(admin) }

  describe "GET /api/v1/users" do
    it "returns paginated active users" do
      create_list(:user, 3)

      get "/api/v1/users", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_response.size).to eq(3)
    end
  end

  describe "POST /api/v1/users" do
    let(:valid_params) { { user: attributes_for(:user) } }

    it "creates user and enqueues welcome email" do
      expect {
        post "/api/v1/users", params: valid_params, headers: headers
      }.to change(User, :count).by(1)
       .and have_enqueued_mail(UserMailer, :welcome_email)

      expect(response).to have_http_status(:created)
    end
  end
end
```

### Background Jobs

```ruby
# app/jobs/export_users_job.rb
class ExportUsersJob < ApplicationJob
  queue_as :default
  retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3
  discard_on ActiveJob::DeserializationError

  def perform(user_id, format: "csv")
    user = User.find(user_id)
    export = UserExportService.new(user, format:).call

    UserMailer.export_ready(user, export.url).deliver_later
  end
end

# Enqueue from controller or service
ExportUsersJob.perform_later(current_user.id, format: "csv")
```

## Best Practices

### DO

- Run `bundle exec rubocop` and follow the Ruby Style Guide.
- Use `find_each` instead of `each` when iterating over large record sets (batches of 1000).
- Add database indexes for columns used in `WHERE`, `ORDER BY`, and `JOIN` clauses.
- Use `freeze` on string constants to avoid allocations: `ROLE_ADMIN = "admin".freeze`.
- Scope secrets with `Rails.application.credentials` (encrypted) — never commit `.env` files.
- Write request specs over controller specs — they test the full middleware stack.
- Use `ActiveRecord::Base.transaction` for operations that must succeed or fail together.

### DON'T

- DON'T use `update_all` or `delete_all` without understanding they skip callbacks and validations.
- DON'T put query logic in views or controllers — use scopes or query objects.
- DON'T use `default_scope` — it's global and nearly impossible to override cleanly.
- DON'T call `.count` on preloaded associations — use `.size` (which uses the preloaded data) or
  `.length`.
- DON'T use `after_save` callbacks for side effects like sending emails — use service objects or
  jobs.
- DON'T write migrations that are not reversible — always provide `up` and `down` or use reversible
  methods.
- DON'T skip `null: false` constraints in migrations when the model validates presence — the DB is
  the last line of defense.

## Rails Console Tips

```ruby
# Reload code without restarting
reload!

# Show SQL queries in console
ActiveRecord::Base.logger = Logger.new(STDOUT)

# Find slow queries
User.includes(:posts).where(active: true).explain

# Sandbox mode — rolls back all changes on exit
# rails console --sandbox
```
