# Virtual DOM Engine

Diffyne uses a custom Virtual DOM (VDOM) engine to achieve high performance with minimal DOM updates.

## How It Works

### 1. Initial Render

```
Component State → Blade Template → Virtual DOM Tree → HTML → Browser
```

When a component first loads:
1. PHP renders Blade template with component state
2. HTML is parsed into a Virtual DOM tree
3. Virtual DOM is converted to actual HTML
4. HTML sent to browser

### 2. Subsequent Updates

```
State Change → Re-render → New VDOM → Diff → Patches → Browser
```

When state changes:
1. Component re-renders to new Virtual DOM
2. Diff algorithm compares old VDOM vs new VDOM
3. Minimal patches generated
4. Patches sent to browser
5. Browser applies patches to real DOM

## Virtual DOM Structure

A Virtual DOM node looks like:

```php
[
    'type' => 'element',
    'tag' => 'div',
    'attrs' => ['class' => 'container', 'id' => 'app'],
    'children' => [
        [
            'type' => 'text',
            'content' => 'Hello World'
        ]
    ]
]
```

## Diff Algorithm

The diff engine compares two VDOM trees and generates minimal patches.

### Text Node Changes

**Before:**
```html
<div>Count: 0</div>
```

**After:**
```html
<div>Count: 1</div>
```

**Patch:**
```json
{
    "type": "text",
    "node": "#text-42",
    "value": "Count: 1"
}
```

### Attribute Changes

**Before:**
```html
<button class="btn">Click</button>
```

**After:**
```html
<button class="btn active">Click</button>
```

**Patch:**
```json
{
    "type": "attr",
    "node": "#btn-1",
    "attr": "class",
    "value": "btn active"
}
```

### Element Addition

**Before:**
```html
<ul>
    <li>Item 1</li>
</ul>
```

**After:**
```html
<ul>
    <li>Item 1</li>
    <li>Item 2</li>
</ul>
```

**Patch:**
```json
{
    "type": "add",
    "parent": "#list-1",
    "html": "<li>Item 2</li>"
}
```

### Element Removal

**Before:**
```html
<div>
    <p>Text</p>
    <button>Click</button>
</div>
```

**After:**
```html
<div>
    <p>Text</p>
</div>
```

**Patch:**
```json
{
    "type": "remove",
    "node": "#btn-1"
}
```

## Patch Types

Diffyne supports these patch types:

| Type | Description | Example |
|------|-------------|---------|
| `text` | Update text content | Change "0" to "1" |
| `attr` | Update attribute | Add/remove class |
| `add` | Add new element | Insert list item |
| `remove` | Remove element | Delete button |
| `replace` | Replace element | Swap div with span |
| `move` | Reorder elements | Drag-drop reorder |

## Performance Benefits

### Traditional Approach (HTMX/Livewire)

Sends full HTML fragment:

```html
<!-- 423 bytes -->
<div class="p-6 max-w-sm mx-auto bg-white rounded-xl shadow-md">
    <div class="text-center">
        <h2 class="text-2xl font-bold mb-4">Counter</h2>
        <div class="text-6xl font-bold mb-6 text-blue-600">1</div>
        <button class="px-6 py-3 bg-green-500">+</button>
    </div>
</div>
```

### Diffyne Approach

Sends minimal patch:

```json
// 52 bytes
{"type":"text","node":"#count","value":"1"}
```

**Result:** 88% smaller payload!

## Optimization Strategies

### 1. Keyed Lists

Use keys for list items:

```blade
@foreach($items as $item)
    <li key="{{ $item['id'] }}">{{ $item['name'] }}</li>
@endforeach
```

This helps the diff algorithm:
- Identify moved items
- Avoid unnecessary re-renders
- Maintain component state

### 2. Conditional Rendering

```blade
@if($showDetails)
    <div>Details...</div>
@endif
```

When `$showDetails` changes:
- True → Adds element (one patch)
- False → Removes element (one patch)

### 3. Static Regions

Mark static content:

```blade
<div>
    {{-- Static header (never changes) --}}
    <header>
        <h1>My App</h1>
    </header>
    
    {{-- Dynamic content --}}
    <div>{{ $dynamicContent }}</div>
</div>
```

The diff engine skips static regions.

## Minified Response Format

Diffyne minifies patch responses:

```json
{
    "s": true,
    "c": {
        "i": "comp-1",
        "p": [
            {"t": "text", "n": "#count", "v": "1"}
        ],
        "st": {"count": 1}
    }
}
```

Key mapping:
- `s` → success
- `c` → component
- `i` → id
- `p` → patches
- `t` → type
- `n` → node
- `v` → value
- `st` → state

## Benchmarks

Typical payload sizes:

| Operation | HTML Size | Diffyne Patch | Savings |
|-----------|-----------|---------------|---------|
| Counter increment | 423 bytes | 52 bytes | 88% |
| Todo add | 1.2 KB | 156 bytes | 87% |
| Text update | 856 bytes | 89 bytes | 90% |
| List reorder | 2.4 KB | 234 bytes | 90% |

## Implementation Details

### Node Identification

Each DOM node gets a unique ID:

```html
<div data-diffyne-id="comp-1-div-0">
    <p data-diffyne-id="comp-1-p-1">Text</p>
</div>
```

This allows precise targeting in patches.

### Patch Application

Browser applies patches in order:

```javascript
function applyPatch(patch) {
    switch(patch.type) {
        case 'text':
            document.getElementById(patch.node).textContent = patch.value;
            break;
        case 'attr':
            document.getElementById(patch.node)
                .setAttribute(patch.attr, patch.value);
            break;
        case 'add':
            document.getElementById(patch.parent)
                .insertAdjacentHTML('beforeend', patch.html);
            break;
        // ... other patch types
    }
}
```

### State Hydration

After patches applied, component state is updated:

```javascript
component.state = response.c.st;
```

This keeps client and server in sync.

## Comparison with Other Frameworks

### vs. Livewire

**Livewire:**
- Sends full HTML fragments
- Uses morphing algorithm
- ~1-5 KB per update

**Diffyne:**
- Sends minimal patches
- Uses Virtual DOM diff
- ~50-200 bytes per update

### vs. Alpine.js

**Alpine.js:**
- Client-side only
- No server state management
- Fast but limited

**Diffyne:**
- Server-driven
- Full Laravel integration
- Fast with server-side logic

### vs. Inertia.js

**Inertia.js:**
- SPA-like experience
- Vue/React required
- Larger payload

**Diffyne:**
- Traditional server rendering
- No frontend framework needed
- Minimal payload

## Future Optimizations

Planned improvements:

1. **Binary patches** - Use binary format instead of JSON
2. **Patch batching** - Combine multiple patches
3. **Delta compression** - Compress patch data
4. **Streaming** - Stream patches as they're generated
5. **Partial hydration** - Only hydrate visible components

## Next Steps

- [Lifecycle Hooks](lifecycle-hooks.md) - Component lifecycle
- [Component State](component-state.md) - State management
- [Performance](performance.md) - Optimization tips
