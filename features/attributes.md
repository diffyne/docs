# Component Attributes

Diffyne provides several PHP attributes (annotations) to control component behavior, security, and state management.

## Overview

Attributes are PHP 8+ features that let you add metadata to classes, properties, and methods. Diffyne uses them to configure components declaratively.

## Available Attributes

| Attribute | Target | Purpose |
|-----------|--------|---------|
| `#[Locked]` | Property | Prevent client-side updates |
| `#[QueryString]` | Property | Sync with URL query parameters |
| `#[Computed]` | Property | Mark as computed (not in state) |
| `#[Invokable]` | Method | Allow client to call method |
| `#[On]` | Method | Register event listener |
| `#[Lazy]` | Class | Lazy load component |

## #[Locked]

Prevents a property from being updated from the client. Use for server-controlled data.

### Usage

```php
use Diffyne\Attributes\Locked;

class PostList extends Component
{
    #[Locked]
    public array $posts = []; // Cannot be changed from client
    
    #[Locked]
    public int $total = 0; // Server-controlled
    
    public int $page = 1; // Can be changed from client
}
```

### When to Use

- **Server-controlled data**: Database results, computed totals, configuration
- **Security**: Prevent tampering with sensitive data
- **Derived values**: Values calculated from other properties

### Example

```php
class ShoppingCart extends Component
{
    #[Locked]
    public array $items = []; // Server loads from database
    
    #[Locked]
    public float $subtotal = 0.0; // Calculated server-side
    
    #[Locked]
    public float $tax = 0.0; // Calculated server-side
    
    #[Locked]
    public float $total = 0.0; // Calculated server-side
    
    public function addItem(int $productId): void
    {
        // Only server can modify items
        $product = Product::find($productId);
        $this->items[] = $product->toArray();
        $this->recalculateTotals();
    }
    
    private function recalculateTotals(): void
    {
        $this->subtotal = array_sum(array_column($this->items, 'price'));
        $this->tax = $this->subtotal * 0.08;
        $this->total = $this->subtotal + $this->tax;
    }
}
```

**Security Note**: Attempting to update a locked property from the client will result in a `400 Bad Request` error.

## #[QueryString]

Syncs a property with the URL query string. Perfect for filters, pagination, and shareable URLs.

### Usage

```php
use Diffyne\Attributes\QueryString;

class PostList extends Component
{
    #[QueryString]
    public string $search = '';
    
    #[QueryString]
    public int $page = 1;
    
    #[QueryString(keep: true)]
    public ?string $filter = null; // Keeps empty values in URL
}
```

### Parameters

- `as` (string|null): Custom query parameter name
- `history` (bool): Push to browser history (default: `true`)
- `keep` (bool): Keep empty values in URL (default: `false`)

### Examples

```php
class ProductSearch extends Component
{
    // Simple query string binding
    #[QueryString]
    public string $q = '';
    
    // Custom parameter name
    #[QueryString(as: 'category_id')]
    public ?int $categoryId = null;
    
    // Keep in URL even when empty
    #[QueryString(keep: true)]
    public string $sort = 'name';
    
    // No history push (replace current state)
    #[QueryString(history: false)]
    public string $view = 'grid';
}
```

### URL Behavior

```php
// Component state
$search = 'laptop';
$page = 2;

// URL becomes: /products?search=laptop&page=2
```

When user changes `$page` to `3`:
- URL updates to: `/products?search=laptop&page=3`
- Browser history is updated (unless `history: false`)
- Page reload preserves state from URL

### Best Practices

1. **Use for filters and pagination**:
```php
#[QueryString]
public string $status = 'all';

#[QueryString]
public int $page = 1;
```

2. **Keep important state in URL**:
```php
#[QueryString(keep: true)]
public string $viewMode = 'grid';
```

3. **Use custom names for cleaner URLs**:
```php
#[QueryString(as: 'cat')]
public ?int $categoryId = null;
// URL: ?cat=5 instead of ?categoryId=5
```

## #[Computed]

Marks a property as computed (derived from other properties). Computed properties are excluded from state serialization.

### Usage

```php
use Diffyne\Attributes\Computed;

class ShoppingCart extends Component
{
    public array $items = [];
    
    #[Computed]
    public float $total = 0.0; // Calculated, not stored
    
    public function getTotal(): float
    {
        return array_sum(array_column($this->items, 'price'));
    }
}
```

### When to Use

- **Derived values**: Values calculated from other properties
- **Performance**: Avoid storing redundant data
- **Consistency**: Always calculate from source of truth

### Example

```php
class TodoList extends Component
{
    public array $todos = [];
    
    #[Computed]
    public int $completedCount = 0;
    
    #[Computed]
    public int $remainingCount = 0;
    
    public function getCompletedCount(): int
    {
        return count(array_filter($this->todos, fn($t) => $t['completed']));
    }
    
    public function getRemainingCount(): int
    {
        return count($this->todos) - $this->getCompletedCount();
    }
}
```

In the view:

```blade
<p>{{ $this->getCompletedCount() }} completed</p>
<p>{{ $this->getRemainingCount() }} remaining</p>
```

**Note**: Computed properties are automatically hidden from state and cannot be updated from the client.

## #[Invokable]

Marks a method as callable from the client. **Security feature**: Only methods with this attribute can be invoked.

### Usage

```php
use Diffyne\Attributes\Invokable;

class PostList extends Component
{
    #[Invokable]
    public function deletePost(int $id): void
    {
        Post::find($id)->delete();
        $this->loadPosts();
    }
    
    // This method CANNOT be called from client
    private function loadPosts(): void
    {
        $this->posts = Post::all()->toArray();
    }
}
```

### Security

By default, **no methods are invokable**. You must explicitly mark methods with `#[Invokable]`:

```php
class UserForm extends Component
{
    #[Invokable]
    public function save(): void
    {
        // Can be called from client
    }
    
    public function validateEmail(): void
    {
        // CANNOT be called from client (no attribute)
    }
    
    #[Invokable]
    public function cancel(): void
    {
        // Can be called from client
    }
}
```

### Best Practices

1. **Only mark public actions as invokable**:
```php
#[Invokable]
public function submit(): void { } // ✅ Public action

#[Invokable]
public function delete(int $id): void { } // ✅ Public action

// Don't mark internal methods
private function loadData(): void { } // ❌ Internal
```

2. **Use for all user-triggered actions**:
```php
#[Invokable]
public function increment(): void { }

#[Invokable]
public function decrement(): void { }

#[Invokable]
public function reset(): void { }
```

## #[On]

Registers a method as an event listener. The method will be called when the specified event is dispatched.

### Usage

```php
use Diffyne\Attributes\On;

class NotificationCenter extends Component
{
    #[On('user-updated')]
    public function handleUserUpdate(array $data): void
    {
        $userId = $data['id'] ?? null;
        $this->showNotification("User {$userId} was updated");
    }
    
    #[On('post-deleted')]
    public function handlePostDeleted(array $data): void
    {
        $this->refreshPostList();
    }
}
```

### Multiple Listeners

You can listen to multiple events on the same method:

```php
#[On('user-created')]
#[On('user-updated')]
public function handleUserChange(array $data): void
{
    $this->refreshUserList();
}
```

### Event Parameters

Events can pass data to listeners:

```php
// Dispatching component
$this->dispatch('user-updated', ['id' => 123, 'name' => 'John']);

// Listening component
#[On('user-updated')]
public function handleUserUpdate(array $data): void
{
    $userId = $data['id']; // 123
    $name = $data['name']; // 'John'
}
```

### Example: Cross-Component Communication

```php
// PostList.php
class PostList extends Component
{
    #[Invokable]
    public function deletePost(int $id): void
    {
        Post::find($id)->delete();
        $this->loadPosts();
        
        // Notify other components
        $this->dispatch('post-deleted', ['id' => $id]);
    }
}

// NotificationBar.php
class NotificationBar extends Component
{
    public array $notifications = [];
    
    #[On('post-deleted')]
    public function handlePostDeleted(array $data): void
    {
        $this->notifications[] = [
            'message' => 'Post deleted successfully',
            'timestamp' => now(),
        ];
    }
}
```

## #[Lazy]

Marks a component class for lazy loading. The component will only be loaded when it becomes visible.

### Usage

```php
use Diffyne\Attributes\Lazy;

#[Lazy]
class HeavyComponent extends Component
{
    public function mount(): void
    {
        // This only runs when component becomes visible
        $this->loadExpensiveData();
    }
}
```

### With Placeholder

```php
#[Lazy(placeholder: '<div>Loading...</div>')]
class ProductList extends Component
{
    // ...
}
```

### When to Use

- **Heavy components**: Components that load lots of data
- **Below-the-fold content**: Content not immediately visible
- **Performance optimization**: Reduce initial page load time

## Combining Attributes

You can combine multiple attributes:

```php
class AdvancedComponent extends Component
{
    #[Locked]
    #[QueryString]
    public int $total = 0; // Locked AND synced with URL
    
    #[Invokable]
    #[On('refresh-requested')]
    public function refresh(): void
    {
        // Can be called from client AND listens to events
        $this->loadData();
    }
}
```

## Best Practices

### 1. Use #[Locked] for Server Data

```php
// ✅ Good
#[Locked]
public array $posts = [];

// ❌ Avoid - allows client tampering
public array $posts = [];
```

### 2. Use #[QueryString] for Shareable State

```php
// ✅ Good - URL is shareable
#[QueryString]
public string $search = '';

// ❌ Avoid - state lost on refresh
public string $search = '';
```

### 3. Use #[Invokable] Explicitly

```php
// ✅ Good - explicit security
#[Invokable]
public function save(): void { }

// ❌ Avoid - implicit (not secure)
public function save(): void { }
```

### 4. Use #[On] for Loose Coupling

```php
// ✅ Good - components communicate via events
#[On('data-updated')]
public function refresh(): void { }

// ❌ Avoid - tight coupling
public function refreshFromOtherComponent(): void { }
```

## Next Steps

- [Component State](advanced/component-state.md) - State management
- [Security](advanced/security.md) - Security features
- [Component Events](features/component-events.md) - Event system
- [Query String Binding](features/query-string.md) - URL synchronization

