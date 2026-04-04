---
name: elixir-development
description: >-
  Elixir and OTP best practices, patterns, and idioms for building concurrent,
  fault-tolerant applications. Use when the task involves `Elixir project`, `mix.exs`,
  `Phoenix framework`, `GenServer`, or `OTP patterns`.
license: MIT
metadata:
  version: "1.0.0"
---

# Elixir Development

Production patterns for Elixir/OTP programming, covering Mix projects, GenServer, Supervisors,
pattern matching, testing with ExUnit, and Phoenix basics.

## When to Use This Skill

- Starting or structuring an Elixir project
- Building concurrent systems with OTP
- Implementing GenServers and Supervisors
- Writing pattern-matching-driven code
- Testing with ExUnit
- Working with Phoenix web framework
- Querying databases with Ecto

## Core Concepts

### 1. Project Layout (Mix)

```
myapp/
├── lib/
│   ├── myapp/
│   │   ├── application.ex     # OTP Application (supervisor tree root)
│   │   ├── accounts/
│   │   │   ├── user.ex        # Ecto schema
│   │   │   └── accounts.ex    # Context module (business logic)
│   │   ├── workers/
│   │   │   └── email_worker.ex
│   │   └── repo.ex            # Ecto Repo
│   └── myapp.ex               # Public API
├── test/
│   ├── myapp/
│   │   └── accounts_test.exs
│   ├── support/
│   │   └── fixtures.ex
│   └── test_helper.exs
├── config/
│   ├── config.exs
│   ├── dev.exs
│   ├── test.exs
│   └── runtime.exs
├── mix.exs
├── mix.lock
└── README.md
```

### 2. Key Principles

| Principle        | Elixir Idiom                                       |
|------------------|----------------------------------------------------|
| Immutability     | All data is immutable; transform, don't mutate     |
| Pattern matching | Destructure and branch in function heads           |
| Pipe operator    | Chain transformations with `                       |>`                      |
| Let it crash     | Supervisors restart failed processes automatically |
| Processes        | Lightweight, isolated; communicate via messages    |

## Quick Start

```bash
# Create a new project
mix new myapp --sup   # --sup includes Application supervisor

# Create a Phoenix project
mix phx.new myapp

# Get dependencies
mix deps.get

# Run tests
mix test
mix test --cover

# Interactive shell
iex -S mix

# Format code
mix format
```

## Patterns

### Pattern 1: Pattern Matching and Guards

```elixir
defmodule MyApp.Parser do
  # Multi-clause functions — pattern match in function heads
  def parse(%{"type" => "user", "data" => data}), do: parse_user(data)
  def parse(%{"type" => "order", "data" => data}), do: parse_order(data)
  def parse(%{"type" => type}), do: {:error, "Unknown type: #{type}"}
  def parse(_), do: {:error, "Invalid payload"}

  # Guards for additional constraints
  def process_age(age) when is_integer(age) and age >= 0 and age <= 150 do
    cond do
      age < 18 -> :minor
      age < 65 -> :adult
      true -> :senior
    end
  end

  def process_age(_), do: {:error, :invalid_age}

  # Pin operator to match against existing values
  def find_by_name(users, target_name) do
    Enum.find(users, fn %{name: ^target_name} -> true; _ -> false end)
  end

  # With clause for complex matching pipelines
  def create_user(params) do
    with {:ok, name} <- validate_name(params["name"]),
         {:ok, email} <- validate_email(params["email"]),
         {:ok, user} <- Repo.insert(%User{name: name, email: email}) do
      {:ok, user}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
```

### Pattern 2: GenServer

```elixir
defmodule MyApp.Cache do
  use GenServer

  # --- Client API ---

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, %{}, name: name)
  end

  def get(server \\ __MODULE__, key) do
    GenServer.call(server, {:get, key})
  end

  def put(server \\ __MODULE__, key, value, ttl \\ :infinity) do
    GenServer.cast(server, {:put, key, value, ttl})
  end

  def delete(server \\ __MODULE__, key) do
    GenServer.cast(server, {:delete, key})
  end

  # --- Server Callbacks ---

  @impl true
  def init(state) do
    # Schedule periodic cleanup
    schedule_cleanup()
    {:ok, state}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    case Map.get(state, key) do
      {value, expiry} when expiry == :infinity ->
        {:reply, {:ok, value}, state}

      {value, expiry} ->
        if System.monotonic_time(:second) < expiry do
          {:reply, {:ok, value}, state}
        else
          {:reply, :miss, Map.delete(state, key)}
        end

      nil ->
        {:reply, :miss, state}
    end
  end

  @impl true
  def handle_cast({:put, key, value, ttl}, state) do
    expiry =
      case ttl do
        :infinity -> :infinity
        seconds -> System.monotonic_time(:second) + seconds
      end

    {:noreply, Map.put(state, key, {value, expiry})}
  end

  @impl true
  def handle_cast({:delete, key}, state) do
    {:noreply, Map.delete(state, key)}
  end

  @impl true
  def handle_info(:cleanup, state) do
    now = System.monotonic_time(:second)

    cleaned =
      state
      |> Enum.reject(fn {_k, {_v, exp}} -> exp != :infinity and now >= exp end)
      |> Map.new()

    schedule_cleanup()
    {:noreply, cleaned}
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, :timer.seconds(60))
  end
end
```

### Pattern 3: Supervisor Trees

```elixir
defmodule MyApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start Repo before anything that needs DB
      MyApp.Repo,
      # Named cache process
      {MyApp.Cache, name: MyApp.Cache},
      # Dynamic supervisor for on-demand workers
      {DynamicSupervisor, name: MyApp.WorkerSupervisor, strategy: :one_for_one},
      # Task supervisor for fire-and-forget async work
      {Task.Supervisor, name: MyApp.TaskSupervisor},
      # Phoenix endpoint last (depends on all the above)
      MyAppWeb.Endpoint,
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

# Spawn workers dynamically
defmodule MyApp.WorkerManager do
  def start_worker(job) do
    DynamicSupervisor.start_child(
      MyApp.WorkerSupervisor,
      {MyApp.Worker, job}
    )
  end

  # Fire-and-forget async task (supervised)
  def send_email_async(email) do
    Task.Supervisor.start_child(MyApp.TaskSupervisor, fn ->
      MyApp.Mailer.deliver(email)
    end)
  end
end
```

### Pattern 4: Pipe Operator and Transformations

```elixir
defmodule MyApp.DataPipeline do
  # Pipe operator chains transformations left-to-right
  def process_orders(raw_data) do
    raw_data
    |> Jason.decode!()
    |> Map.get("orders", [])
    |> Enum.filter(&(&1["status"] == "active"))
    |> Enum.map(&normalize_order/1)
    |> Enum.sort_by(& &1.total, :desc)
    |> Enum.take(10)
  end

  defp normalize_order(%{"id" => id, "amount" => amount, "currency" => curr}) do
    %{
      id: id,
      total: convert_currency(amount, curr, "USD"),
      currency: "USD"
    }
  end

  # Enum vs Stream — Stream for lazy evaluation on large datasets
  def process_large_file(path) do
    path
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.reject(&(&1 == ""))
    |> Stream.map(&parse_line/1)
    |> Stream.filter(&(&1.valid?))
    |> Enum.to_list()
  end
end
```

### Pattern 5: Ecto Queries

```elixir
defmodule MyApp.Accounts do
  import Ecto.Query

  alias MyApp.Repo
  alias MyApp.Accounts.User

  def list_active_users do
    User
    |> where([u], u.active == true)
    |> order_by([u], desc: u.inserted_at)
    |> Repo.all()
  end

  def get_user!(id), do: Repo.get!(User, id)

  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  # Composable queries
  def list_users(filters) do
    User
    |> maybe_filter_role(filters[:role])
    |> maybe_filter_active(filters[:active])
    |> maybe_search(filters[:search])
    |> Repo.all()
  end

  defp maybe_filter_role(query, nil), do: query
  defp maybe_filter_role(query, role), do: where(query, [u], u.role == ^role)

  defp maybe_filter_active(query, nil), do: query
  defp maybe_filter_active(query, active), do: where(query, [u], u.active == ^active)

  defp maybe_search(query, nil), do: query
  defp maybe_search(query, term) do
    where(query, [u], ilike(u.name, ^"%#{term}%"))
  end
end
```

### Pattern 6: Testing with ExUnit

```elixir
defmodule MyApp.AccountsTest do
  use MyApp.DataCase, async: true

  alias MyApp.Accounts
  alias MyApp.Accounts.User

  describe "create_user/1" do
    test "creates user with valid attributes" do
      attrs = %{name: "Alice", email: "alice@example.com", role: :admin}

      assert {:ok, %User{} = user} = Accounts.create_user(attrs)
      assert user.name == "Alice"
      assert user.email == "alice@example.com"
    end

    test "returns error changeset with invalid email" do
      attrs = %{name: "Alice", email: "invalid"}

      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user(attrs)
      assert %{email: ["has invalid format"]} = errors_on(changeset)
    end
  end

  describe "list_users/1" do
    setup do
      admin = insert_user(%{name: "Admin", role: :admin, active: true})
      viewer = insert_user(%{name: "Viewer", role: :viewer, active: false})
      %{admin: admin, viewer: viewer}
    end

    test "filters by role", %{admin: admin} do
      result = Accounts.list_users(%{role: :admin})
      assert [^admin] = result
    end

    test "filters by active status", %{admin: admin} do
      result = Accounts.list_users(%{active: true})
      assert [^admin] = result
    end
  end

  defp insert_user(attrs) do
    {:ok, user} =
      %{name: "Test", email: "#{System.unique_integer()}@test.com", role: :viewer, active: true}
      |> Map.merge(attrs)
      |> Accounts.create_user()

    user
  end
end
```

## Best Practices

### Do's

- **Use the pipe operator `|>`** — For clear data transformation chains
- **Pattern match in function heads** — Instead of `if`/`case` inside the body
- **Use `with` for multi-step operations** — Cleaner than nested `case` blocks
- **Let processes crash** — Supervisors handle restarts; don't over-rescue
- **Use `@impl true`** — Marks callback implementations explicitly
- **Tag return tuples** — `{:ok, value}` and `{:error, reason}` consistently
- **Run `mix format`** — Before every commit

### Don'ts

- **Don't use `try/rescue` for flow control** — Use pattern matching and tagged tuples
- **Don't store state in module attributes at runtime** — Use GenServer or ETS
- **Don't create long pipes with side effects** — Pipes are for transformations
- **Don't ignore `@spec` typespecs** — Add them on public functions for Dialyzer
- **Don't use `String.to_atom` on user input** — Atoms are never garbage collected
- **Don't block GenServer calls with long work** — Offload to Task or cast

## Resources

- [Elixir Getting Started](https://elixir-lang.org/getting-started/introduction.html)
- [Phoenix Guides](https://hexdocs.pm/phoenix/overview.html)
- [Ecto Documentation](https://hexdocs.pm/ecto/Ecto.html)
- [Elixir School](https://elixirschool.com/)
