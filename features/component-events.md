# Component Events

Diffyne provides a powerful event system for component-to-component communication. Events allow components to communicate without tight coupling.

## Overview

Events enable:
- **Loose coupling**: Components don't need to know about each other
- **Cross-component communication**: One component can notify others
- **Reactive updates**: Components can react to changes in other components
- **Browser integration**: Dispatch JavaScript events for third-party libraries

## Event Types

### 1. Component Events

Events dispatched to other Diffyne components:

```php
$this->dispatch('user-updated', ['id' => 123]);
```

### 2. Browser Events

JavaScript custom events dispatched to the browser:

```php
$this->dispatchBrowserEvent('notification', ['message' => 'Saved!']);
```

## Dispatching Events

### dispatch()

Dispatch an event to all listening components:

```php
class UserForm extends Component
{
    #[Invokable]
    public function save(): void
    {
        $user = User::create($this->validated);
        
        // Notify all components listening for 'user-created'
        $this->dispatch('user-created', [
            'id' => $user->id,
            'name' => $user->name,
        ]);
    }
}
```

### dispatchTo()

Dispatch an event to specific component(s):

```php
// To a single component
$this->dispatchTo('user-list', 'refresh-requested');

// To multiple components
$this->dispatchTo(['user-list', 'user-stats'], 'refresh-requested');

// With data
$this->dispatchTo('user-list', 'user-updated', [
    'id' => 123,
    'name' => 'John',
]);
```

### dispatchSelf()

Dispatch an event only to this component:

```php
public function processData(): void
{
    // Do some work...
    
    // Notify self
    $this->dispatchSelf('data-processed', [
        'count' => $this->processedCount,
    ]);
}

#[On('data-processed')]
public function handleDataProcessed(array $data): void
{
    // Handle the event
}
```

### dispatchBrowserEvent()

Dispatch a JavaScript custom event:

```php
public function save(): void
{
    // Save data...
    
    // Dispatch browser event
    $this->dispatchBrowserEvent('data-saved', [
        'message' => 'Data saved successfully!',
        'timestamp' => now()->toIso8601String(),
    ]);
}
```

In JavaScript:

```javascript
// Listen for the event
window.addEventListener('data-saved', (event) => {
    console.log(event.detail.message);
    // Show notification, update UI, etc.
});
```

## Listening to Events

### Using #[On] Attribute

Register event listeners using the `#[On]` attribute:

```php
use Diffyne\Attributes\On;

class NotificationBar extends Component
{
    public array $notifications = [];
    
    #[On('user-created')]
    public function handleUserCreated(array $data): void
    {
        $this->notifications[] = [
            'message' => "User {$data['name']} was created",
            'timestamp' => now(),
        ];
    }
    
    #[On('user-updated')]
    public function handleUserUpdated(array $data): void
    {
        $this->notifications[] = [
            'message' => "User {$data['name']} was updated",
            'timestamp' => now(),
        ];
    }
}
```

### Multiple Listeners

Listen to multiple events on the same method:

```php
#[On('user-created')]
#[On('user-updated')]
#[On('user-deleted')]
public function handleUserChange(array $data): void
{
    $this->refreshUserList();
}
```

### Event Parameters

Events can pass data to listeners:

```php
// Dispatching
$this->dispatch('order-placed', [
    'orderId' => 123,
    'total' => 99.99,
    'items' => ['item1', 'item2'],
]);

// Listening
#[On('order-placed')]
public function handleOrderPlaced(array $data): void
{
    $orderId = $data['orderId']; // 123
    $total = $data['total']; // 99.99
    $items = $data['items']; // ['item1', 'item2']
}
```

## Examples

### Example 1: Post List with Notifications

**PostList.php**:

```php
class PostList extends Component
{
    #[Locked]
    public array $posts = [];
    
    #[Invokable]
    public function deletePost(int $id): void
    {
        Post::find($id)->delete();
        $this->loadPosts();
        
        // Notify other components
        $this->dispatch('post-deleted', ['id' => $id]);
        
        // Also notify browser
        $this->dispatchBrowserEvent('post-deleted', [
            'id' => $id,
            'message' => 'Post deleted successfully',
        ]);
    }
    
    private function loadPosts(): void
    {
        $this->posts = Post::all()->toArray();
    }
}
```

**NotificationBar.php**:

```php
class NotificationBar extends Component
{
    public array $notifications = [];
    
    #[On('post-deleted')]
    public function handlePostDeleted(array $data): void
    {
        $this->notifications[] = [
            'type' => 'success',
            'message' => 'Post deleted successfully',
            'timestamp' => now(),
        ];
    }
}
```

### Example 2: Shopping Cart Updates

**ShoppingCart.php**:

```php
class ShoppingCart extends Component
{
    #[Locked]
    public array $items = [];
    
    #[Invokable]
    public function addItem(int $productId): void
    {
        $product = Product::find($productId);
        $this->items[] = $product->toArray();
        
        // Notify cart summary
        $this->dispatchTo('cart-summary', 'cart-updated', [
            'itemCount' => count($this->items),
        ]);
        
        // Notify product list
        $this->dispatchTo('product-list', 'item-added', [
            'productId' => $productId,
        ]);
    }
}
```

**CartSummary.php**:

```php
class CartSummary extends Component
{
    public int $itemCount = 0;
    
    #[On('cart-updated')]
    public function handleCartUpdated(array $data): void
    {
        $this->itemCount = $data['itemCount'];
    }
}
```

### Example 3: Page Change Logger

**PostList.php**:

```php
class PostList extends Component
{
    public int $page = 1;
    
    #[Invokable]
    public function nextPage(): void
    {
        $this->page++;
        $this->loadPosts();
        
        // Dispatch component event
        $this->dispatch('page-changing', [
            'newPage' => $this->page,
            'totalPages' => $this->totalPages,
        ]);
        
        // Dispatch browser event
        $this->dispatchBrowserEvent('page-navigated', [
            'page' => $this->page,
            'total' => $this->totalPages,
        ]);
    }
}
```

**PageChangeLogger.php**:

```php
class PageChangeLogger extends Component
{
    public array $logs = [];
    
    #[On('page-changing')]
    public function handlePageChange(array $data): void
    {
        $this->logs[] = [
            'timestamp' => now()->format('H:i:s'),
            'page' => $data['newPage'],
            'totalPages' => $data['totalPages'],
        ];
        
        // Keep only last 10 logs
        if (count($this->logs) > 10) {
            array_shift($this->logs);
        }
    }
}
```

### Example 4: Confirmation Modal

**PostList.php**:

```php
class PostList extends Component
{
    #[Invokable]
    public function confirmDelete(int $id): void
    {
        $post = Post::find($id);
        
        // Open confirmation modal
        $this->dispatch('open-confirmation-modal', [
            'title' => 'Delete Post',
            'message' => "Are you sure you want to delete \"{$post->title}\"?",
            'confirmText' => 'Delete',
            'cancelText' => 'Cancel',
            'eventName' => 'delete-post-confirmed',
            'eventData' => ['id' => $id],
        ]);
    }
    
    #[On('delete-post-confirmed')]
    public function deletePost(array $data): void
    {
        $id = $data['id'] ?? null;
        
        if ($id) {
            Post::find($id)->delete();
            $this->loadPosts();
        }
    }
}
```

**ConfirmationModal.php**:

```php
class ConfirmationModal extends Component
{
    public bool $isOpen = false;
    
    #[Locked]
    public string $title = 'Confirm Action';
    
    #[Locked]
    public string $message = '';
    
    #[Locked]
    public string $eventName = '';
    
    #[Locked]
    public array $eventData = [];
    
    #[On('open-confirmation-modal')]
    public function open(array $data): void
    {
        $this->isOpen = true;
        $this->title = $data['title'] ?? 'Confirm Action';
        $this->message = $data['message'] ?? '';
        $this->eventName = $data['eventName'] ?? '';
        $this->eventData = $data['eventData'] ?? [];
    }
    
    #[Invokable]
    public function confirm(): void
    {
        if ($this->eventName) {
            $this->dispatch($this->eventName, $this->eventData);
        }
        $this->close();
    }
    
    #[Invokable]
    public function close(): void
    {
        $this->isOpen = false;
        $this->eventName = '';
        $this->eventData = [];
    }
}
```

## Browser Events

### JavaScript Integration

Dispatch browser events to integrate with JavaScript libraries:

```php
public function save(): void
{
    // Save data...
    
    // Dispatch to JavaScript
    $this->dispatchBrowserEvent('saved', [
        'message' => 'Data saved!',
        'id' => $this->id,
    ]);
}
```

```javascript
// In your JavaScript
window.addEventListener('saved', (event) => {
    console.log(event.detail.message);
    // Show toast notification
    toast.success(event.detail.message);
});
```

### Third-Party Library Integration

```php
// Dispatch event for analytics
$this->dispatchBrowserEvent('analytics:event', [
    'event' => 'purchase',
    'value' => 99.99,
]);

// In JavaScript
window.addEventListener('analytics:event', (event) => {
    gtag('event', event.detail.event, {
        'value': event.detail.value,
    });
});
```

## Best Practices

### 1. Use Descriptive Event Names

```php
// ✅ Good
$this->dispatch('user-profile-updated', [...]);
$this->dispatch('shopping-cart-item-added', [...]);

// ❌ Bad
$this->dispatch('update', [...]);
$this->dispatch('change', [...]);
```

### 2. Pass Relevant Data

```php
// ✅ Good - includes all needed data
$this->dispatch('order-placed', [
    'orderId' => $order->id,
    'total' => $order->total,
    'items' => $order->items->toArray(),
]);

// ❌ Bad - missing data
$this->dispatch('order-placed', ['id' => $order->id]);
```

### 3. Use Specific Targets When Possible

```php
// ✅ Good - specific target
$this->dispatchTo('cart-summary', 'cart-updated', [...]);

// ⚠️ OK - broadcast to all
$this->dispatch('cart-updated', [...]);
```

### 4. Document Event Contracts

```php
/**
 * Dispatches 'user-updated' event with:
 * - id: int - User ID
 * - name: string - User name
 * - email: string - User email
 */
public function updateUser(): void
{
    // ...
    $this->dispatch('user-updated', [
        'id' => $user->id,
        'name' => $user->name,
        'email' => $user->email,
    ]);
}
```

### 5. Handle Missing Data Gracefully

```php
#[On('user-updated')]
public function handleUserUpdated(array $data): void
{
    $userId = $data['id'] ?? null;
    
    if (!$userId) {
        return; // Skip if missing required data
    }
    
    // Process update...
}
```

## Event Naming Conventions

### Recommended Patterns

- **Verb-noun**: `user-created`, `post-deleted`, `order-placed`
- **Component-action**: `cart-updated`, `form-submitted`, `list-refreshed`
- **Namespace for scoping**: `admin:user-created`, `shop:cart-updated`

### Examples

```php
// User events
'user-created'
'user-updated'
'user-deleted'
'user-logged-in'

// Post events
'post-created'
'post-published'
'post-deleted'

// Cart events
'cart-item-added'
'cart-item-removed'
'cart-updated'
'cart-cleared'
```

## Debugging Events

### Log Events

```php
public function dispatch(string $event, ...$params): self
{
    logger()->debug('Dispatching event', [
        'event' => $event,
        'params' => $params,
    ]);
    
    return parent::dispatch($event, ...$params);
}
```

### Check Registered Listeners

```php
$listeners = $component->getEventListeners();
// Returns: ['user-updated' => ['handleUserUpdated'], ...]
```

## Next Steps

- [Attributes](attributes.md) - Learn about #[On] attribute
- [Component State](advanced/component-state.md) - State management
- [Security](advanced/security.md) - Security considerations
- [Examples](../examples/) - More examples

