# Security

Diffyne includes several security features to protect your application from common attacks and unauthorized state manipulation.

## Overview

Diffyne's security model is based on:

1. **State Signing**: HMAC signatures prevent state tampering
2. **Flexible Verification Modes**: Balance security and usability
3. **Locked Properties**: Server-controlled properties cannot be modified from client
4. **Method Whitelisting**: Only explicitly marked methods can be invoked
5. **Rate Limiting**: Prevents abuse and DoS attacks

## State Signing

Every component state is signed with an HMAC signature using your application key. This prevents clients from tampering with state data.

### How It Works

1. **Server sends state with signature**:
```json
{
  "id": "diffyne-abc123",
  "state": {
    "count": 5,
    "name": "John"
  },
  "signature": "a1b2c3d4e5f6..."
}
```

2. **Client sends state back with signature**:
```json
{
  "componentId": "diffyne-abc123",
  "state": {
    "count": 5,
    "name": "John"
  },
  "signature": "a1b2c3d4e5f6..."
}
```

3. **Server verifies signature**:
   - If signature matches: Request is processed
   - If signature doesn't match: `403 Forbidden` error

## Security Modes

Diffyne offers flexible security configuration to balance security and usability:

### 1. `property-updates` (Recommended - Default)

**What it does:**
- ✅ Verifies signatures for property updates (`diff:model.live`, `diff:model.lazy`)
- ✅ Allows form submissions without strict signature verification

**Best for:** Most applications - provides security where it matters most while maintaining good UX.

**Configuration:**
```php
// config/diffyne.php
'security' => [
    'verify_state' => 'property-updates',
],
```

Or via `.env`:
```
DIFFYNE_VERIFY_STATE=property-updates
```

### 2. `strict`

**What it does:**
- ✅ Verifies signatures for ALL requests (form submissions + property updates)
- ✅ Uses lenient verification for form submissions (if enabled)
- ⚠️ May cause issues with form submissions if state reconstruction fails

**Best for:** High-security applications where you need maximum protection.

**Configuration:**
```php
'security' => [
    'verify_state' => 'strict',
    'lenient_form_verification' => true, // Recommended
],
```

### 3. `none` or `false`

**What it does:**
- ❌ Disables signature verification entirely
- ⚠️ Not recommended for production

**Best for:** Development only, or when you have other security measures in place.

### Configuration

```php
// config/diffyne.php
'security' => [
    // Signing key (defaults to APP_KEY)
    'signing_key' => env('DIFFYNE_SIGNING_KEY'),
    
    // Verify state signature mode: 'property-updates', 'strict', or false
    'verify_state' => env('DIFFYNE_VERIFY_STATE', 'property-updates'),
    
    // Allow lenient verification for form submissions (strict mode only)
    'lenient_form_verification' => env('DIFFYNE_LENIENT_FORMS', true),
    
    // Rate limiting (requests per minute)
    'rate_limit' => env('DIFFYNE_RATE_LIMIT', 60),
],
```

### Recommended Configuration

For most applications, use this configuration:

```php
'security' => [
    'verify_state' => 'property-updates',
    'lenient_form_verification' => true,
    'rate_limit' => 60,
],
```

This provides:
- ✅ Security for property updates (where tampering is most likely)
- ✅ Smooth form submission experience
- ✅ Rate limiting to prevent abuse

## Locked Properties

Properties marked with `#[Locked]` cannot be updated from the client. This prevents tampering with server-controlled data.

### Example

```php
use Diffyne\Attributes\Locked;

class PostList extends Component
{
    #[Locked]
    public array $posts = []; // Server-controlled
    
    #[Locked]
    public int $total = 0; // Server-calculated
    
    public int $page = 1; // Client can change
}
```

### Security Benefits

1. **Prevent Data Tampering**: Users can't modify server data
2. **Protect Calculations**: Totals, counts, etc. are server-only
3. **Enforce Business Logic**: Only server can modify critical data

### Attempting to Update Locked Property

If a client tries to update a locked property:

```javascript
// This will fail
fetch('/_diffyne/update', {
    method: 'POST',
    body: JSON.stringify({
        property: 'posts',
        value: [], // Trying to clear posts
        // ...
    })
});
```

**Response**: `400 Bad Request` with error: `"Cannot update locked property: posts"`

## Method Whitelisting

Only methods marked with `#[Invokable]` can be called from the client. This provides explicit security control.

### Example

```php
use Diffyne\Attributes\Invokable;

class UserForm extends Component
{
    #[Invokable]
    public function save(): void
    {
        // ✅ Can be called from client
    }
    
    public function loadData(): void
    {
        // ❌ CANNOT be called from client
    }
    
    #[Invokable]
    public function delete(): void
    {
        // ✅ Can be called from client
    }
}
```

### Security Benefits

1. **Explicit Control**: You decide what's callable
2. **Prevent Unauthorized Actions**: Internal methods are protected
3. **Clear Intent**: Easy to see what's public API

### Attempting to Call Non-Invokable Method

```javascript
// This will fail
fetch('/_diffyne/call', {
    method: 'POST',
    body: JSON.stringify({
        method: 'loadData', // Not marked #[Invokable]
        // ...
    })
});
```

**Response**: `400 Bad Request` with error: `"Method loadData is not invokable"`

## Rate Limiting

Diffyne includes built-in rate limiting to prevent abuse and DoS attacks.

### Configuration

```php
// config/diffyne.php
'security' => [
    'rate_limit' => env('DIFFYNE_RATE_LIMIT', 60), // requests per minute
],
```

### How It Works

- Each IP address is limited to N requests per minute
- Exceeding the limit returns `429 Too Many Requests`
- Limits are per-route (update, call, etc.)

### Customizing Rate Limits

You can customize rate limits in your middleware or route configuration:

```php
// In your service provider or middleware
RateLimiter::for('diffyne', function (Request $request) {
    return Limit::perMinute(100)->by($request->ip());
});
```

## Testing Security

### Test 1: Tamper with State Signature

```javascript
// In browser console
const component = document.querySelector('[diff\\:id]');
const componentId = component.getAttribute('diff:id');
const state = JSON.parse(component.getAttribute('diff:state'));

// Try to tamper with signature
fetch('/_diffyne/update', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
    },
    body: JSON.stringify({
        componentId: componentId,
        property: 'page',
        value: 2,
        state: state,
        signature: 'tampered_signature_12345', // ❌ Invalid signature
    })
})
.then(r => r.json())
.then(data => {
    console.log('Result:', data);
    // Expected: 403 Forbidden - "Invalid state signature"
});
```

### Test 2: Try to Update Locked Property

```javascript
const component = document.querySelector('[diff\\:id]');
const componentId = component.getAttribute('diff:id');
const state = JSON.parse(component.getAttribute('diff:state'));
const signature = component.getAttribute('diff:signature');

// Try to update locked property
fetch('/_diffyne/update', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
    },
    body: JSON.stringify({
        componentId: componentId,
        property: 'posts', // Locked property
        value: [], // Trying to clear
        state: state,
        signature: signature,
    })
})
.then(r => r.json())
.then(data => {
    console.log('Result:', data);
    // Expected: 400 Bad Request - "Cannot update locked property: posts"
});
```

### Test 3: Try to Call Non-Invokable Method

```javascript
const component = document.querySelector('[diff\\:id]');
const componentId = component.getAttribute('diff:id');
const state = JSON.parse(component.getAttribute('diff:state'));
const signature = component.getAttribute('diff:signature');

// Try to call non-invokable method
fetch('/_diffyne/call', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
    },
    body: JSON.stringify({
        componentId: componentId,
        method: 'loadData', // Not marked #[Invokable]
        params: [],
        state: state,
        signature: signature,
    })
})
.then(r => r.json())
.then(data => {
    console.log('Result:', data);
    // Expected: 400 Bad Request - "Method loadData is not invokable"
});
```

## Best Practices

### 1. Always Use #[Locked] for Server Data

```php
// ✅ Good
#[Locked]
public array $posts = [];

// ❌ Bad - allows tampering
public array $posts = [];
```

### 2. Mark Only Public Actions as #[Invokable]

```php
// ✅ Good - public action
#[Invokable]
public function save(): void { }

// ❌ Bad - internal method
#[Invokable]
public function loadData(): void { }
```

### 3. Use Appropriate Verification Mode

```bash
# ✅ Good - recommended for most apps
DIFFYNE_VERIFY_STATE=property-updates

# ✅ Good - maximum security
DIFFYNE_VERIFY_STATE=strict

# ❌ Bad - only for development
DIFFYNE_VERIFY_STATE=false
```

### 4. Set Appropriate Rate Limits

```php
// ✅ Good - reasonable limit
'rate_limit' => 60, // 1 request per second

// ❌ Bad - too high (allows abuse)
'rate_limit' => 10000,

// ❌ Bad - too low (breaks UX)
'rate_limit' => 5,
```

### 5. Use Strong Signing Keys

```bash
# ✅ Good - use APP_KEY (strong, random)
DIFFYNE_SIGNING_KEY=

# ❌ Bad - weak key
DIFFYNE_SIGNING_KEY=secret123
```

### 6. Validate All Input

Even with locked properties, always validate:

```php
#[Invokable]
public function updateName(string $name): void
{
    // ✅ Always validate
    $validated = $this->validate([
        'name' => 'required|string|max:255',
    ]);
    
    $this->name = $validated['name'];
}
```

## Common Security Patterns

### Pattern 1: Server-Controlled Lists

```php
class ProductList extends Component
{
    #[Locked]
    public array $products = []; // Server loads
    
    #[Locked]
    public int $total = 0; // Server calculates
    
    public string $search = ''; // Client can change
    
    public function updatedSearch(): void
    {
        // Server reloads products based on search
        $this->loadProducts();
    }
    
    private function loadProducts(): void
    {
        $query = Product::query();
        
        if ($this->search) {
            $query->where('name', 'like', "%{$this->search}%");
        }
        
        $this->products = $query->get()->toArray();
        $this->total = count($this->products);
    }
}
```

### Pattern 2: Protected Actions

```php
class AdminPanel extends Component
{
    #[Invokable]
    public function deleteUser(int $id): void
    {
        // ✅ Always check authorization
        if (!auth()->user()->isAdmin()) {
            abort(403);
        }
        
        User::find($id)->delete();
    }
}
```

### Pattern 3: Validated Updates

```php
class UserForm extends Component
{
    public string $email = '';
    
    #[Invokable]
    public function updateEmail(): void
    {
        // ✅ Always validate
        $validated = $this->validate([
            'email' => 'required|email|unique:users',
        ]);
        
        $this->email = $validated['email'];
    }
}
```

## Troubleshooting

### Form submissions failing with signature errors?

1. Check your `.env` file:
   ```
   DIFFYNE_VERIFY_STATE=property-updates
   ```

2. Clear config cache:
   ```bash
   php artisan config:clear
   ```

3. Verify state signature is being sent correctly

### Migration from strict mode

If you were experiencing issues with strict verification:

```php
// Old (causing issues)
'verify_state' => true, // or 'verify_state' => env('DIFFYNE_VERIFY_STATE', true)

// New (recommended)
'verify_state' => 'property-updates', // or env('DIFFYNE_VERIFY_STATE', 'property-updates')
```

No code changes needed - your forms will now work smoothly while property updates remain secure.

## Security Checklist

- [ ] All server-controlled data uses `#[Locked]`
- [ ] Only public actions are marked `#[Invokable]`
- [ ] State verification is configured appropriately (`DIFFYNE_VERIFY_STATE=property-updates` recommended)
- [ ] Rate limiting is configured appropriately
- [ ] All user input is validated
- [ ] Authorization checks are in place for sensitive actions
- [ ] Signing key is strong (using APP_KEY)
- [ ] Security testing has been performed

## Next Steps

Learn more about keeping your app secure:

- [Attributes](/features/attributes) - Use Locked and Invokable attributes
- [Component State](/advanced/component-state) - Understand state management
- [Validation](/features/validation) - Validate user input
- [Testing](/advanced/testing) - Test your security features

