# Lifecycle Hooks

Diffyne components have lifecycle hooks that let you run code at specific points in the component's lifecycle.

## Available Hooks

| Hook | When It Runs | Use Case |
|------|--------------|----------|
| `mount()` | Once when component first loads | Initialize data, load from database |
| `hydrate()` | Before each request | Restore session data, check auth |
| `updating($property, $value)` | Before property updates | Validate, transform data |
| `updated($property)` | After property updates | React to changes, trigger side effects |
| `dehydrate()` | After request, before response | Clean up, prepare for serialization |

## mount()

Runs once when the component is first created.

```php
public function mount($userId = null)
{
    if ($userId) {
        $this->user = User::find($userId);
    }
    
    $this->items = Item::all()->toArray();
}
```

**Common uses:**
- Load initial data
- Accept route parameters
- Set default values

## hydrate()

Runs on every request after component is instantiated.

```php
public function hydrate()
{
    // Reattach database models
    if ($this->userId) {
        $this->user = User::find($this->userId);
    }
}
```

**Common uses:**
- Restore relationships
- Check authentication
- Reattach models

## updating($property, $value)

Runs before a property is updated.

```php
public function updating(string $property, mixed $value)
{
    // Runs before any property updates
    logger("Updating: $property to $value");
}

public function updatingEmail(string $value)
{
    // Runs specifically before email updates
    return strtolower($value);
}
```

**Common uses:**
- Validate input
- Transform data
- Prevent updates conditionally

## updated($property)

Runs after a property is updated.

```php
public function updated(string $property)
{
    // Runs after any property updates
    if ($property === 'search') {
        $this->loadResults();
    }
}

public function updatedSearch(string $value)
{
    // Runs specifically after search updates
    $this->loadResults();
}
```

**Common uses:**
- React to changes
- Trigger searches
- Validate fields

## dehydrate()

Runs after the request is processed, before sending response.

```php
public function dehydrate()
{
    // Clean up before serialization
    unset($this->temporaryData);
}
```

**Common uses:**
- Clean up temporary data
- Remove non-serializable properties
- Log state changes

## Examples

### Loading Data on Mount

```php
class ProductList extends Component
{
    public array $products = [];
    public string $category = 'all';
    
    public function mount($category = 'all')
    {
        $this->category = $category;
        $this->loadProducts();
    }
    
    private function loadProducts()
    {
        $query = Product::query();
        
        if ($this->category !== 'all') {
            $query->where('category', $this->category);
        }
        
        $this->products = $query->get()->toArray();
    }
}
```

### Live Search with updated()

```php
class Search extends Component
{
    public string $query = '';
    public array $results = [];
    
    public function updated($field)
    {
        if ($field === 'query') {
            $this->search();
        }
    }
    
    private function search()
    {
        $this->results = Product::where('name', 'like', "%{$this->query}%")
            ->limit(10)
            ->get()
            ->toArray();
    }
}
```

### Transform Input with updating()

```php
class UserForm extends Component
{
    public string $username = '';
    public string $email = '';
    
    public function updatingUsername($value)
    {
        // Force lowercase
        return strtolower(trim($value));
    }
    
    public function updatingEmail($value)
    {
        // Force lowercase and trim
        return strtolower(trim($value));
    }
}
```

### Rehydrate Models with hydrate()

```php
class PostEditor extends Component
{
    public int $postId;
    public ?Post $post = null;
    
    public function mount($postId)
    {
        $this->postId = $postId;
        $this->post = Post::find($postId);
    }
    
    public function hydrate()
    {
        // Reattach model on every request
        $this->post = Post::find($this->postId);
    }
    
    public function save()
    {
        $this->post->update([
            'title' => $this->title,
            'content' => $this->content,
        ]);
    }
}
```

## Best Practices

### 1. Use mount() for Initialization

```php
// Good
public function mount()
{
    $this->items = Item::all()->toArray();
}

// Avoid - use mount() instead
public array $items = []; // Don't load in property
```

### 2. Use updated() for Side Effects

```php
public function updated($field)
{
    if ($field === 'category') {
        $this->loadProducts();
        $this->resetPage();
    }
}
```

### 3. Use hydrate() for Non-Serializable Properties

```php
public function hydrate()
{
    // Reattach model
    $this->user = User::find($this->userId);
}
```

### 4. Clean Up in dehydrate()

```php
public function dehydrate()
{
    // Remove temporary data
    unset($this->tempFile);
}
```

## Next Steps

- [Component State](component-state.md) - State management
- [Virtual DOM](virtual-dom.md) - How rendering works
- [Performance](performance.md) - Optimization tips
