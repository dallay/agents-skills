---
name: swift-ios-development
description: >-
  Swift and iOS development patterns covering language fundamentals, UIKit, SwiftUI,
  Combine, async/await, testing with XCTest, project structure, and dependency management
  with SPM. Use when the task involves `Swift`, `iOS development`, `Xcode project`,
  `UIKit`, or `Swift programming`.
license: MIT
metadata:
  version: "1.0.0"
---

## When to Use

- Building iOS, iPadOS, macOS, watchOS, or tvOS applications.
- Writing Swift code for any Apple platform or server-side Swift.
- Working with UIKit view controllers, Auto Layout, or navigation.
- Building declarative UIs with SwiftUI.
- Implementing async/await concurrency or reactive data flows.
- Writing unit or UI tests with XCTest.

## Swift Language Patterns

### Optionals — Null Safety

```swift
// guard let — preferred for early returns
func greet(name: String?) {
    guard let name = name else { return }
    print("Hello, \(name)")
}

// Optional chaining + nil coalescing
let length = user?.profile?.bio?.count
let displayName = user.nickname ?? user.fullName ?? "Anonymous"
```

### Protocols and Extensions

```swift
protocol Repository {
    associatedtype Entity: Identifiable
    func findById(_ id: Entity.ID) async throws -> Entity?
    func save(_ entity: Entity) async throws
}

// Default implementations via extension
extension Repository {
    func findByIdOrFail(_ id: Entity.ID) async throws -> Entity {
        guard let entity = try await findById(id) else {
            throw RepositoryError.notFound(id: "\(id)")
        }
        return entity
    }
}

// Extend existing types
extension Date {
    var isToday: Bool { Calendar.current.isDateInToday(self) }
}

extension Array where Element: Numeric {
    var sum: Element { reduce(0, +) }
}
```

### Enums with Associated Values

```swift
enum NetworkResult<T: Decodable> {
    case success(T)
    case failure(NetworkError)
    case loading
}

enum Route: Hashable {
    case home
    case userDetail(userId: UUID)
    case settings(tab: SettingsTab)
}

// Pattern matching
switch result {
case .success(let data):
    updateUI(with: data)
case .failure(let error) where error.isRetryable:
    scheduleRetry()
case .failure(let error):
    showError(error)
case .loading:
    showSpinner()
}
```

### Generics

```swift
func fetch<T: Decodable>(from url: URL) async throws -> T {
    let (data, response) = try await URLSession.shared.data(from: url)
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw NetworkError.invalidResponse
    }
    return try JSONDecoder().decode(T.self, from: data)
}
```

## UIKit Patterns

### View Controller Lifecycle

```swift
class UserDetailViewController: UIViewController {
    private let userId: UUID
    private let repository: UserRepository

    // Dependency injection via initializer
    init(userId: UUID, repository: UserRepository) {
        self.userId = userId
        self.repository = repository
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("Use init(userId:repository:)") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        Task {
            do {
                let user = try await repository.findByIdOrFail(userId)
                updateUI(with: user)
            } catch { showError(error) }
        }
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        let stack = UIStackView(arrangedSubviews: [nameLabel, emailLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }
}
```

## SwiftUI Essentials

### State, Binding, ObservableObject

```swift
import SwiftUI

// @State for local view state
struct CounterView: View {
    @State private var count = 0
    var body: some View {
        Button("Count: \(count)") { count += 1 }
            .buttonStyle(.borderedProminent)
    }
}

// @Binding for child → parent communication
struct SettingsToggle: View {
    @Binding var isEnabled: Bool
    let title: String
    var body: some View { Toggle(title, isOn: $isEnabled) }
}

// ObservableObject + @StateObject for shared state (pre-iOS 17)
class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false

    @MainActor
    func loadUser(id: UUID) async {
        isLoading = true
        defer { isLoading = false }
        user = try? await UserRepository.shared.findById(id)
    }
}

struct UserView: View {
    @StateObject private var vm = UserViewModel()
    let userId: UUID

    var body: some View {
        Group {
            if vm.isLoading { ProgressView() }
            else if let user = vm.user { Text(user.name) }
        }
        .task { await vm.loadUser(id: userId) }
    }
}
```

### iOS 17+ Observation Framework

```swift
import Observation

@Observable
class AppState {
    var currentUser: User?
    var theme: Theme = .system
}

struct RootView: View {
    @State private var appState = AppState()
    var body: some View {
        ContentView().environment(appState)
    }
}

struct ContentView: View {
    @Environment(AppState.self) private var appState
    var body: some View {
        // Tracks only properties actually read
        Text(appState.currentUser?.name ?? "Guest")
    }
}
```

## Async/Await Concurrency

```swift
// Parallel async with async let
func fetchDashboard() async throws -> Dashboard {
    async let profile = fetchProfile()
    async let notifications = fetchNotifications()
    return Dashboard(
        profile: try await profile,
        notifications: try await notifications
    )
}

// Actor for thread-safe mutable state
actor ImageCache {
    private var cache: [URL: UIImage] = [:]

    func image(for url: URL) async throws -> UIImage {
        if let cached = cache[url] { return cached }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw ImageError.invalidData
        }
        cache[url] = image
        return image
    }
}
```

## XCTest Testing

```swift
import XCTest
@testable import MyApp

final class UserRepositoryTests: XCTestCase {
    private var sut: UserRepository!
    private var mockAPI: MockAPIClient!

    override func setUp() {
        super.setUp()
        mockAPI = MockAPIClient()
        sut = UserRepository(api: mockAPI)
    }

    override func tearDown() {
        sut = nil
        mockAPI = nil
        super.tearDown()
    }

    func test_findById_returnsUser_whenAPISucceeds() async throws {
        // Given
        let expected = User(id: UUID(), name: "Ada", email: "ada@example.com")
        mockAPI.stubbedResponse = expected
        // When
        let user = try await sut.findById(expected.id)
        // Then
        XCTAssertEqual(user?.name, "Ada")
    }

    func test_findById_throwsError_whenAPIFails() async {
        mockAPI.stubbedError = NetworkError.serverError(500)
        do {
            _ = try await sut.findById(UUID())
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
}
```

## Project Structure

```
MyApp/
├── App/
│   └── MyApp.swift              # @main entry point
├── Features/
│   ├── Auth/    (Views/, ViewModels/, Models/)
│   └── Dashboard/
├── Core/
│   ├── Network/ (APIClient.swift, Endpoints.swift)
│   ├── Storage/
│   └── Extensions/
├── Resources/   (Assets.xcassets, Localizable.strings)
└── Tests/       (UnitTests/, UITests/)
```

## Dependency Management (SPM)

```swift
// Package.swift — swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyLibrary",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [.library(name: "MyLibrary", targets: ["MyLibrary"])],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
    ],
    targets: [
        .target(name: "MyLibrary", dependencies: ["Alamofire"]),
        .testTarget(name: "MyLibraryTests", dependencies: ["MyLibrary"]),
    ]
)
```

## Best Practices

### DO

- **Use `guard let` for early returns** — keeps the happy path unindented and readable.
- **Use `async/await`** over completion handlers — cleaner, safer, integrates with structured
  concurrency.
- **Use `@MainActor`** for view models and UI code — prevents data races on the main thread.
- **Use protocols for dependencies** — enables testing via mock/stub injection.
- **Use value types (structs/enums)** by default — classes only for reference semantics or
  inheritance.
- **Use `[weak self]` in escaping closures** to prevent retain cycles.
- **Use `Codable`** for JSON — built-in, type-safe serialization.
- **Use `@Observable` (iOS 17+)** over `ObservableObject` — simpler and more efficient.
- **Test behavior, not implementation** — assert outcomes through public API.

### DON'T

- **DON'T force-unwrap (`!`) in production code** — use `guard let`, `if let`, or `??` instead.
- **DON'T use `var` when `let` works** — immutability by default prevents bugs.
- **DON'T put business logic in Views/ViewControllers** — extract to view models or use cases.
- **DON'T ignore `@Sendable` warnings** — they indicate potential data races.
- **DON'T use singletons for dependencies** — inject via initializers for testability.
- **DON'T block the main thread** — use `async/await` or `DispatchQueue` for heavy work.
- **DON'T use `NotificationCenter` for everything** — prefer delegates, closures, or Combine.
- **DON'T skip `setUp`/`tearDown`** in XCTest — fresh state per test prevents flaky tests.
- **DON'T catch errors silently** — at minimum log them; surface to user when appropriate.
- **DON'T ignore App Store Review Guidelines** — validate entitlements, Info.plist privacy keys, and
  prohibited APIs.

## Commands

```bash
# Swift packages
swift package init --type library
swift build
swift test

# Xcode
xcodebuild -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15' build
xcodebuild test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Resources

- [Swift Language Guide](https://docs.swift.org/swift-book/)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Swift Package Manager Docs](https://www.swift.org/documentation/package-manager/)
