---
name: php-development
description: >-
  Modern PHP 8.x+ best practices, patterns, and standards for building robust
  applications. Use when the task involves `PHP project`, `composer.json`, `PHP
  development`, `Laravel`, or `Symfony`.
license: MIT
metadata:
  version: "1.0.0"
---
# PHP Development

Production patterns for modern PHP (8.x+), covering Composer, PSR standards, type safety,
testing with PHPUnit, and architectural best practices.

## When to Use This Skill

- Building or structuring a PHP application
- Working with Composer for dependency management
- Following PSR standards (autoloading, coding style)
- Using PHP 8.x features (attributes, enums, fibers, typed properties)
- Writing tests with PHPUnit
- Applying clean architecture in PHP projects

## Core Concepts

### 1. Project Layout (PSR-4)

```
myapp/
├── src/
│   ├── Controller/
│   │   └── UserController.php
│   ├── Service/
│   │   └── UserService.php
│   ├── Repository/
│   │   └── UserRepository.php
│   ├── Entity/
│   │   └── User.php
│   ├── Exception/
│   │   ├── AppException.php
│   │   └── NotFoundException.php
│   └── ValueObject/
│       └── Email.php
├── tests/
│   ├── Unit/
│   │   └── Service/
│   │       └── UserServiceTest.php
│   └── Integration/
│       └── Repository/
│           └── UserRepositoryTest.php
├── config/
├── public/
│   └── index.php
├── composer.json
├── phpunit.xml
└── README.md
```

### 2. Key Standards

| Standard | Purpose                                |
|----------|----------------------------------------|
| PSR-4    | Autoloading: namespace ↔ directory map |
| PSR-12   | Extended coding style (superseded by PER-CS) |
| PSR-7    | HTTP message interfaces                |
| PSR-11   | Container interface (DI)               |
| PSR-3    | Logger interface                       |

## Quick Start

```bash
# Initialize project
composer init

# Install dependencies
composer require guzzlehttp/guzzle
composer require --dev phpunit/phpunit phpstan/phpstan

# Autoload (PSR-4 in composer.json)
composer dump-autoload

# Run tests
./vendor/bin/phpunit

# Static analysis
./vendor/bin/phpstan analyse src --level=max

# Code style fix
./vendor/bin/php-cs-fixer fix src
```

```json
{
    "autoload": {
        "psr-4": {
            "App\\": "src/"
        }
    },
    "autoload-dev": {
        "psr-4": {
            "App\\Tests\\": "tests/"
        }
    }
}
```

## Patterns

### Pattern 1: Type-Safe PHP 8.x

```php
<?php

declare(strict_types=1);

namespace App\Entity;

// Enums (PHP 8.1+)
enum UserRole: string
{
    case Admin = 'admin';
    case Editor = 'editor';
    case Viewer = 'viewer';

    public function canEdit(): bool
    {
        return match ($this) {
            self::Admin, self::Editor => true,
            self::Viewer => false,
        };
    }
}

// Readonly classes (PHP 8.2+)
readonly class User
{
    public function __construct(
        public string $id,
        public string $name,
        public Email $email,
        public UserRole $role = UserRole::Viewer,
        public \DateTimeImmutable $createdAt = new \DateTimeImmutable(),
    ) {}
}

// Value objects with validation
readonly class Email
{
    public function __construct(
        public string $value,
    ) {
        if (!filter_var($value, FILTER_VALIDATE_EMAIL)) {
            throw new \InvalidArgumentException("Invalid email: {$value}");
        }
    }

    public function __toString(): string
    {
        return $this->value;
    }
}
```

### Pattern 2: Error Handling

```php
<?php

declare(strict_types=1);

namespace App\Exception;

// Base exception for the application
class AppException extends \RuntimeException
{
    public function __construct(
        string $message,
        public readonly array $context = [],
        int $code = 0,
        ?\Throwable $previous = null,
    ) {
        parent::__construct($message, $code, $previous);
    }
}

class NotFoundException extends AppException
{
    public static function forEntity(string $entity, string $id): self
    {
        return new self(
            message: "{$entity} with ID {$id} not found",
            context: ['entity' => $entity, 'id' => $id],
            code: 404,
        );
    }
}

class ValidationException extends AppException
{
    public function __construct(
        public readonly array $errors,
    ) {
        parent::__construct(
            message: 'Validation failed',
            context: ['errors' => $errors],
            code: 422,
        );
    }
}

// Usage in service layer
class UserService
{
    public function __construct(
        private readonly UserRepository $repository,
        private readonly LoggerInterface $logger,
    ) {}

    public function find(string $id): User
    {
        try {
            $user = $this->repository->findById($id);
        } catch (\PDOException $e) {
            $this->logger->error('Database error', ['id' => $id, 'error' => $e->getMessage()]);
            throw new AppException('Failed to fetch user', previous: $e);
        }

        if ($user === null) {
            throw NotFoundException::forEntity('User', $id);
        }

        return $user;
    }
}
```

### Pattern 3: Interfaces and Dependency Injection

```php
<?php

declare(strict_types=1);

namespace App\Repository;

// Define contracts with interfaces
interface UserRepositoryInterface
{
    public function findById(string $id): ?User;
    public function save(User $user): void;
    public function delete(string $id): void;
    /** @return User[] */
    public function findByRole(UserRole $role): array;
}

// Concrete implementation
class PostgresUserRepository implements UserRepositoryInterface
{
    public function __construct(
        private readonly \PDO $connection,
    ) {}

    public function findById(string $id): ?User
    {
        $stmt = $this->connection->prepare('SELECT * FROM users WHERE id = :id');
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch(\PDO::FETCH_ASSOC);

        return $row ? $this->hydrate($row) : null;
    }

    public function save(User $user): void
    {
        $stmt = $this->connection->prepare(
            'INSERT INTO users (id, name, email, role)
             VALUES (:id, :name, :email, :role)
             ON CONFLICT (id) DO UPDATE SET name = :name, email = :email, role = :role'
        );
        $stmt->execute([
            'id' => $user->id,
            'name' => $user->name,
            'email' => (string) $user->email,
            'role' => $user->role->value,
        ]);
    }

    // ...
}
```

### Pattern 4: Attributes (PHP 8.0+)

```php
<?php

declare(strict_types=1);

namespace App\Attribute;

#[\Attribute(\Attribute::TARGET_METHOD)]
class Route
{
    public function __construct(
        public readonly string $path,
        public readonly string $method = 'GET',
    ) {}
}

#[\Attribute(\Attribute::TARGET_PROPERTY)]
class Validate
{
    public function __construct(
        public readonly string $rule,
        public readonly string $message = 'Validation failed',
    ) {}
}

// Usage
class UserController
{
    #[Route('/users/{id}', method: 'GET')]
    public function show(string $id): Response
    {
        // ...
    }

    #[Route('/users', method: 'POST')]
    public function create(Request $request): Response
    {
        // ...
    }
}

// Reading attributes at runtime
function getRoutes(string $controllerClass): array
{
    $routes = [];
    $reflection = new \ReflectionClass($controllerClass);

    foreach ($reflection->getMethods() as $method) {
        $attributes = $method->getAttributes(Route::class);
        foreach ($attributes as $attr) {
            $route = $attr->newInstance();
            $routes[] = [
                'path' => $route->path,
                'method' => $route->method,
                'handler' => [$controllerClass, $method->getName()],
            ];
        }
    }

    return $routes;
}
```

### Pattern 5: Testing with PHPUnit

```php
<?php

declare(strict_types=1);

namespace App\Tests\Unit\Service;

use App\Entity\User;
use App\Entity\Email;
use App\Entity\UserRole;
use App\Exception\NotFoundException;
use App\Repository\UserRepositoryInterface;
use App\Service\UserService;
use PHPUnit\Framework\TestCase;
use Psr\Log\NullLogger;

class UserServiceTest extends TestCase
{
    private UserRepositoryInterface $repository;
    private UserService $service;

    protected function setUp(): void
    {
        $this->repository = $this->createMock(UserRepositoryInterface::class);
        $this->service = new UserService($this->repository, new NullLogger());
    }

    public function testFindReturnsUser(): void
    {
        $user = new User(
            id: '123',
            name: 'Alice',
            email: new Email('alice@example.com'),
        );

        $this->repository
            ->method('findById')
            ->with('123')
            ->willReturn($user);

        $result = $this->service->find('123');

        $this->assertSame($user, $result);
    }

    public function testFindThrowsNotFoundForMissingUser(): void
    {
        $this->repository
            ->method('findById')
            ->with('999')
            ->willReturn(null);

        $this->expectException(NotFoundException::class);
        $this->expectExceptionMessage('User with ID 999 not found');

        $this->service->find('999');
    }

    /**
     * @dataProvider invalidEmailProvider
     */
    public function testEmailValidation(string $email): void
    {
        $this->expectException(\InvalidArgumentException::class);
        new Email($email);
    }

    public static function invalidEmailProvider(): array
    {
        return [
            'empty' => [''],
            'no at sign' => ['invalid'],
            'no domain' => ['user@'],
            'spaces' => ['user @example.com'],
        ];
    }
}
```

## Best Practices

### Do's

- **Use `declare(strict_types=1)`** — In every PHP file for type safety
- **Use readonly classes/properties** — For value objects and DTOs
- **Use enums over class constants** — Type-safe, self-documenting
- **Use constructor promotion** — Reduces boilerplate
- **Use named arguments** — For readability: `new User(name: 'Alice', role: UserRole::Admin)`
- **Use `match` over `switch`** — Strict comparison, expression-based
- **Run PHPStan at max level** — Catch type errors before runtime

### Don'ts

- **Don't use `@` error suppression** — Hides bugs
- **Don't use `global` variables** — Use dependency injection
- **Don't use `extract()`** — Creates variables from unknown keys
- **Don't catch `\Exception` without rethrowing** — Swallows critical errors
- **Don't use dynamic properties (deprecated in 8.2)** — Declare all properties
- **Don't use `mixed` type when a specific type is known** — Be precise

## Resources

- [PHP The Right Way](https://phptherightway.com/)
- [PHP-FIG PSR Standards](https://www.php-fig.org/psr/)
- [PHPStan Documentation](https://phpstan.org/)
- [Modern PHP Features](https://stitcher.io/blog/new-in-php-83)
