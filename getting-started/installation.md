# Installation

## Requirements

- PHP 8.1 or higher
- Laravel 10.0, 11.0, or 12.0
- Composer

## Step-by-Step Installation

### 1. Install via Composer

```bash
composer require diffyne/diffyne
```

### 2. Publish Configuration

Publish the configuration file to customize Diffyne settings:

```bash
php artisan vendor:publish --tag=diffyne-config
```

This creates `config/diffyne.php` where you can configure:
- Transport mode (AJAX or WebSocket)
- Component namespace
- View path
- Debug mode
- Security settings
- Performance options
- WebSocket configuration

### 3. Publish Assets

Publish the JavaScript runtime to your public directory:

```bash
php artisan vendor:publish --tag=diffyne-assets
```

This copies `diffyne.js` to `public/vendor/diffyne/diffyne.js`.

### 4. Add Scripts to Layout

In your main layout file (e.g., `resources/views/layouts/app.blade.php`), add the Diffyne scripts directive before the closing `</body>` tag:

```blade
<!DOCTYPE html>
<html>
<head>
    <title>My App</title>
    <!-- Your other head content -->
</head>
<body>
    <!-- Your content -->
    
    @diffyneScripts
</body>
</html>
```

The `@diffyneScripts` directive includes:
- The Diffyne JavaScript runtime
- CSRF token configuration
- Component initialization

## Verification

To verify your installation is working:

1. Create a test component:
```bash
php artisan make:diffyne TestComponent
```

2. Add it to a view:
```blade
@diffyne('TestComponent')
```

3. Visit the page in your browser and check the browser console for any errors.

## Asset Building (Development)

If you're developing Diffyne itself or need to rebuild assets:

```bash
cd packages/diffyne
npm install
npm run build
```

This compiles and minifies the JavaScript runtime.

## Configuration

### Basic Configuration

The `config/diffyne.php` file contains these options:

```php
return [
    // Transport mode: 'ajax' or 'websocket'
    'transport' => env('DIFFYNE_TRANSPORT', 'ajax'),
    
    // Component namespace
    'component_namespace' => 'App\\Diffyne',
    
    // View path for component templates
    'view_path' => resource_path('views/diffyne'),
    
    // Enable debug mode for detailed error messages
    'debug' => env('DIFFYNE_DEBUG', false),
    
    // Security settings
    'security' => [
        'signing_key' => env('DIFFYNE_SIGNING_KEY'), // Defaults to APP_KEY
        'verify_state' => env('DIFFYNE_VERIFY_STATE', true),
        'rate_limit' => env('DIFFYNE_RATE_LIMIT', 60),
    ],
    
    // Performance options
    'performance' => [
        'cache_rendered_views' => env('DIFFYNE_CACHE_VIEWS', true),
        'minify_patches' => env('DIFFYNE_MINIFY_PATCHES', true),
        'debounce_default' => 150,
        'max_request_size' => 512 * 1024,
        'enable_compression' => env('DIFFYNE_COMPRESSION', true),
    ],
    
    // WebSocket configuration (when using 'websocket' transport)
    'websocket' => [
        'host' => env('DIFFYNE_WS_HOST', '127.0.0.1'),
        'port' => env('DIFFYNE_WS_PORT', 6001),
        'path' => env('DIFFYNE_WS_PATH', '/diffyne'),
        'key' => env('DIFFYNE_WS_KEY'),
        'cors' => [
            'allowed_origins' => explode(',', env('DIFFYNE_WS_CORS_ORIGINS', '*')),
            'allowed_methods' => ['GET', 'POST', 'OPTIONS'],
            'allowed_headers' => ['Content-Type', 'Authorization', 'X-CSRF-TOKEN'],
        ],
    ],
];
```

### Environment Variables

Add these to your `.env` file:

```env
# Transport mode
DIFFYNE_TRANSPORT=ajax

# Debug mode
DIFFYNE_DEBUG=false

# Security
DIFFYNE_VERIFY_STATE=true
DIFFYNE_RATE_LIMIT=60

# Performance
DIFFYNE_CACHE_VIEWS=true
DIFFYNE_MINIFY_PATCHES=true
DIFFYNE_COMPRESSION=true

# WebSocket (if using websocket transport)
DIFFYNE_WS_HOST=127.0.0.1
DIFFYNE_WS_PORT=6001
DIFFYNE_WS_PATH=/diffyne
DIFFYNE_WS_KEY=your-secret-key
DIFFYNE_WS_CORS_ORIGINS=*
```

## WebSocket Setup (Optional)

Diffyne supports WebSocket transport for real-time, bidirectional communication. This is optional - the default AJAX transport works great for most use cases.

### When to Use WebSocket

- Real-time applications (chat, notifications, live updates)
- High-frequency updates
- Lower latency requirements
- Persistent connections

### Setup Steps

1. **Install Sockeon** (WebSocket server):

```bash
composer require sockeon/sockeon
```

2. **Configure WebSocket in `.env`**:

```env
DIFFYNE_TRANSPORT=websocket
DIFFYNE_WS_HOST=127.0.0.1
DIFFYNE_WS_PORT=6001
DIFFYNE_WS_KEY=your-secret-key-here
```

3. **Start the WebSocket server**:

```bash
php artisan diffyne:websocket
```

Or run it in the background:

```bash
php artisan diffyne:websocket > /dev/null 2>&1 &
```

4. **For production**, use a process manager like Supervisor:

```ini
[program:diffyne-websocket]
command=php /path/to/artisan diffyne:websocket
directory=/path/to/project
autostart=true
autorestart=true
user=www-data
redirect_stderr=true
stdout_logfile=/path/to/logs/diffyne-websocket.log
```

### WebSocket vs AJAX

| Feature | AJAX | WebSocket |
|---------|------|-----------|
| Latency | ~50-200ms | ~10-50ms |
| Connection | Per-request | Persistent |
| Server Load | Lower | Higher |
| Complexity | Simple | Moderate |
| Use Case | Most apps | Real-time apps |

**Recommendation**: Start with AJAX. Switch to WebSocket only if you need real-time features or lower latency.

## Next Steps

- [Quick Start Guide](quickstart.md) - Build your first component
- [Your First Component](first-component.md) - Detailed component creation tutorial
