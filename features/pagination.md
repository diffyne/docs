# Pagination

Display large datasets across multiple pages with automatic URL synchronization and reactive navigation.

## Overview

Pagination in Diffyne is as easy as Livewire. Use the `HasPagination` trait to add pagination functionality to any component. It automatically handles:

- **Page navigation** - Next, previous, and direct page links
- **URL synchronization** - Page number in URL query string
- **State management** - Automatic serialization of paginator objects
- **Reactive updates** - UI updates automatically when page changes

## Quick Start

### 1. Use the Trait

```php
<?php

namespace App\Diffyne;

use Diffyne\Component;
use Diffyne\Traits\HasPagination;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class UserList extends Component
{
    use HasPagination;

    public ?LengthAwarePaginator $users = null;

    public function mount(): void
    {
        $this->loadUsers();
    }

    protected function onPageChange(): void
    {
        $this->loadUsers();
    }

    protected function loadUsers(): void
    {
        $this->users = User::query()
            ->orderBy('name')
            ->paginate($this->perPage, ['*'], 'page', $this->page);
    }

    public function render()
    {
        return view('diffyne.user-list');
    }
}
```

### 2. Display Pagination Links

```blade
<div>
    {{-- Your data table --}}
    <table>
        @foreach($users as $user)
            <tr>
                <td>{{ $user->name }}</td>
                <td>{{ $user->email }}</td>
            </tr>
        @endforeach
    </table>

    {{-- Pagination links --}}
    @if($users && $users->hasPages())
        <div class="mt-6">
            {{ $users->links('diffyne::pagination') }}
        </div>
    @endif
</div>
```

That's it! The pagination is fully functional and reactive.

## How It Works

### Automatic Properties

The `HasPagination` trait provides these properties:

- `$page` - Current page number (1-indexed, synced with URL)
- `$perPage` - Items per page (default: 15)

### Automatic Methods

- `nextPage()` - Go to next page
- `previousPage()` - Go to previous page
- `goToPage($page)` - Jump to specific page
- `resetPage()` - Go back to page 1

### Lifecycle Hook

Implement `onPageChange()` to reload data when page changes:

```php
protected function onPageChange(): void
{
    $this->loadUsers();
}
```

## Basic Example

### Component

```php
<?php

namespace App\Diffyne;

use App\Models\Post;
use Diffyne\Component;
use Diffyne\Traits\HasPagination;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class PostList extends Component
{
    use HasPagination;

    public ?LengthAwarePaginator $posts = null;

    public function mount(): void
    {
        $this->loadPosts();
    }

    protected function onPageChange(): void
    {
        $this->loadPosts();
    }

    protected function loadPosts(): void
    {
        $this->posts = Post::query()
            ->latest()
            ->paginate($this->perPage, ['*'], 'page', $this->page);
    }

    public function render()
    {
        return view('diffyne.post-list');
    }
}
```

### View

```blade
<div>
    <h2>Posts</h2>

    @if($posts && $posts->count() > 0)
        <div class="space-y-4">
            @foreach($posts as $post)
                <article class="border p-4">
                    <h3>{{ $post->title }}</h3>
                    <p>{{ $post->excerpt }}</p>
                </article>
            @endforeach
        </div>

        {{-- Pagination --}}
        @if($posts->hasPages())
            <div class="mt-6">
                {{ $posts->links('diffyne::pagination') }}
            </div>
        @endif
    @else
        <p>No posts found.</p>
    @endif
</div>
```

## Customizing Items Per Page

### Change Default

```php
class PostList extends Component
{
    use HasPagination;

    public int $perPage = 25; // Default is 15

    // ...
}
```

### Allow User Selection

```php
use Diffyne\Attributes\Invokable;

#[Invokable]
public function setPerPage(int $perPage): void
{
    $this->perPage = $perPage;
    $this->resetPage(); // Go back to page 1
    $this->onPageChange();
}
```

```blade
<select diff:model.live="perPage">
    <option value="10">10 per page</option>
    <option value="25">25 per page</option>
    <option value="50">50 per page</option>
</select>
```

## Combining with Search

When search changes, reset to page 1:

```php
use Diffyne\Attributes\QueryString;

#[QueryString(keep: true)]
public ?string $search = '';

public function updated(string $property): void
{
    parent::updated($property);

    if ($property === 'search') {
        $this->resetPage();
        $this->loadUsers();
    }
}

protected function loadUsers(): void
{
    $query = User::query();

    if (!empty($this->search)) {
        $query->where('name', 'like', '%'.$this->search.'%');
    }

    $this->users = $query
        ->orderBy('name')
        ->paginate($this->perPage, ['*'], 'page', $this->page);
}
```

## Pagination Helper Methods

The `LengthAwarePaginator` provides useful methods:

```blade
{{-- Check if pagination is needed --}}
@if($users->hasPages())
    {{ $users->links('diffyne::pagination') }}
@endif

{{-- Display info --}}
<p>
    Showing {{ $users->firstItem() }} to {{ $users->lastItem() }} 
    of {{ $users->total() }} results
</p>

{{-- Check page position --}}
@if($users->onFirstPage())
    <p>You're on the first page</p>
@endif

@if($users->hasMorePages())
    <p>More pages available</p>
@endif
```

## URL Synchronization

The `$page` property is automatically synced with the URL query string:

- **Page 1**: `/users`
- **Page 2**: `/users?page=2`
- **Page 3**: `/users?page=3`

Users can:
- **Bookmark** specific pages
- **Share** links to specific pages
- **Use browser back/forward** buttons
- **Refresh** the page and stay on the same page

## Complete Example: Search with Pagination

### Component

```php
<?php

namespace App\Diffyne;

use App\Models\User;
use Diffyne\Attributes\Invokable;
use Diffyne\Attributes\QueryString;
use Diffyne\Component;
use Diffyne\Traits\HasPagination;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class UserList extends Component
{
    use HasPagination;

    public ?LengthAwarePaginator $users = null;
    
    #[QueryString(keep: true)]
    public ?string $search = '';
    
    public bool $loading = false;

    public function mount(): void
    {
        $this->loadUsers();
    }

    public function updated(string $property): void
    {
        parent::updated($property);

        if ($property === 'search') {
            $this->resetPage();
            $this->loadUsers();
        }
    }
    
    #[Invokable]
    public function clearSearch(): void
    {
        $this->search = '';
        $this->resetPage();
        $this->loadUsers();
    }

    protected function onPageChange(): void
    {
        $this->loadUsers();
    }

    protected function loadUsers(): void
    {
        $query = User::query();

        if (!empty($this->search)) {
            $query->where(function ($q) {
                $q->where('name', 'like', '%'.$this->search.'%')
                  ->orWhere('email', 'like', '%'.$this->search.'%');
            });
        }

        $this->users = $query
            ->orderBy('name')
            ->paginate($this->perPage, ['*'], 'page', $this->page);
    }

    public function render()
    {
        return view('diffyne.user-list');
    }
}
```

### View

```blade
<div class="user-list-container">
    {{-- Search --}}
    <div class="mb-4">
        <input 
            type="text" 
            diff:model.live.debounce.300="search"
            placeholder="Search users..."
            class="w-full px-4 py-2 border rounded-lg"
        >
    </div>

    {{-- Results count --}}
    @if($users)
        <p class="text-sm text-gray-600 mb-4">
            Showing {{ $users->firstItem() }} to {{ $users->lastItem() }} 
            of {{ $users->total() }} users
            @if(!empty($search))
                matching "{{ $search }}"
            @endif
        </p>
    @endif

    {{-- Users table --}}
    @if(!$users || $users->isEmpty())
        <p class="text-center py-8 text-gray-500">
            @if(empty($search))
                No users found.
            @else
                No users match "{{ $search }}"
            @endif
        </p>
    @else
        <table class="w-full">
            <thead>
                <tr>
                    <th>Name</th>
                    <th>Email</th>
                </tr>
            </thead>
            <tbody>
                @foreach($users as $user)
                    <tr diff:key="{{ $user->id }}">
                        <td>{{ $user->name }}</td>
                        <td>{{ $user->email }}</td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    @endif

    {{-- Pagination --}}
    @if($users && $users->hasPages())
        <div class="mt-6">
            {{ $users->links('diffyne::pagination') }}
        </div>
    @endif
</div>
```

## Best Practices

### 1. Always Reset Page on Filter Changes

```php
public function updated(string $property): void
{
    if (in_array($property, ['search', 'category', 'status'])) {
        $this->resetPage(); // Important!
        $this->loadData();
    }
}
```

### 2. Use `onPageChange()` Hook

Don't call `loadData()` directly from navigation methods:

```php
// ✅ Good
protected function onPageChange(): void
{
    $this->loadData();
}

// ❌ Avoid
#[Invokable]
public function nextPage(): void
{
    $this->page++;
    $this->loadData(); // Don't do this
}
```

### 3. Check for Empty Results

```blade
@if($users && $users->count() > 0)
    {{-- Display data --}}
@else
    <p>No results found.</p>
@endif
```

### 4. Use `diff:key` for List Items

```blade
@foreach($users as $user)
    <tr diff:key="{{ $user->id }}">
        {{-- Row content --}}
    </tr>
@endforeach
```

This ensures efficient DOM updates when paginating.

### 5. Show Loading States

```blade
<div diff:loading class="opacity-50">
    {{-- Content --}}
</div>
```

## Common Patterns

### Filtering with Pagination

```php
public ?string $status = 'all';
public ?string $category = null;

public function updated(string $property): void
{
    if (in_array($property, ['status', 'category'])) {
        $this->resetPage();
        $this->loadPosts();
    }
}

protected function loadPosts(): void
{
    $query = Post::query();

    if ($this->status !== 'all') {
        $query->where('status', $this->status);
    }

    if ($this->category) {
        $query->where('category_id', $this->category);
    }

    $this->posts = $query
        ->latest()
        ->paginate($this->perPage, ['*'], 'page', $this->page);
}
```

### Sorting with Pagination

```php
use Diffyne\Attributes\Invokable;

public string $sortBy = 'created_at';
public string $sortDir = 'desc';

#[Invokable]
public function sort(string $field): void
{
    if ($this->sortBy === $field) {
        $this->sortDir = $this->sortDir === 'asc' ? 'desc' : 'asc';
    } else {
        $this->sortBy = $field;
        $this->sortDir = 'asc';
    }
    
    $this->resetPage();
    $this->loadData();
}

protected function loadData(): void
{
    $this->items = Item::query()
        ->orderBy($this->sortBy, $this->sortDir)
        ->paginate($this->perPage, ['*'], 'page', $this->page);
}
```

## Troubleshooting

### Pagination Not Updating

**Problem**: Clicking pagination links doesn't change the page.

**Solution**: Make sure you've implemented `onPageChange()`:

```php
protected function onPageChange(): void
{
    $this->loadData(); // Reload data when page changes
}
```

### Page Resets on Every Request

**Problem**: Always goes back to page 1.

**Solution**: Don't reset `$page` in `mount()` or `updated()` unless necessary:

```php
// ❌ Wrong
public function mount(): void
{
    $this->page = 1; // Don't do this
    $this->loadData();
}

// ✅ Correct
public function mount(): void
{
    $this->loadData(); // Page is already 1 by default
}
```

### URL Not Updating

**Problem**: Page number not in URL.

**Solution**: The `$page` property is automatically synced with URL via `#[QueryString]`. If it's not working, check that you're using the trait correctly.

### Empty Results After Pagination

**Problem**: No data shown after changing pages.

**Solution**: Ensure `onPageChange()` calls your data loading method:

```php
protected function onPageChange(): void
{
    $this->loadUsers(); // Make sure this method exists and works
}
```

## Next Steps

- [Query String Binding](/features/query-string) - Learn about URL synchronization
- [Data Binding](/features/data-binding) - Two-way data binding
- [Search Example](/examples/search) - Complete search implementation
- [Component Events](/features/component-events) - Event handling

