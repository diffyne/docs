# WebSocket Transport

Diffyne supports WebSocket transport for real-time, bidirectional communication. This provides lower latency and persistent connections compared to AJAX.

## Overview

WebSocket transport uses [Sockeon](https://sockeon.com) as the WebSocket server, providing high-performance real-time communication.

### When to Use WebSocket

**Use WebSocket when:**
- Building real-time applications (chat, notifications, live updates)
- You need lower latency (< 50ms)
- High-frequency updates (multiple per second)
- Persistent connections are beneficial

**Use AJAX when:**
- Standard web applications
- Occasional updates (every few seconds or less)
- Simpler deployment is preferred
- Lower server resource usage is needed

## Setup

### 1. Install Sockeon

```bash
composer require sockeon/sockeon
```

### 2. Configure WebSocket

Add to your `.env`:

```env
DIFFYNE_TRANSPORT=websocket
DIFFYNE_WS_HOST=127.0.0.1
DIFFYNE_WS_PORT=6001
DIFFYNE_WS_PATH=/diffyne
DIFFYNE_WS_KEY=your-secret-key-here
DIFFYNE_WS_CORS_ORIGINS=*
```

### 3. Start WebSocket Server

```bash
php artisan diffyne:websocket
```

For development, run in background:

```bash
php artisan diffyne:websocket > /dev/null 2>&1 &
```

### 4. Production Setup

Use a process manager like Supervisor:

**`/etc/supervisor/conf.d/diffyne-websocket.conf`**:

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

Then:

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start diffyne-websocket
```

## Configuration

### Basic Configuration

```php
// config/diffyne.php
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
```

### CORS Configuration

For production, restrict CORS origins:

```env
DIFFYNE_WS_CORS_ORIGINS=https://example.com,https://www.example.com
```

### Security Key

Generate a secure key:

```bash
php artisan tinker
>>> Str::random(32)
```

Add to `.env`:

```env
DIFFYNE_WS_KEY=generated-key-here
```

## How It Works

### Connection Flow

1. **Client connects** to WebSocket server
2. **Server authenticates** using key
3. **Persistent connection** established
4. **All requests** go through WebSocket
5. **Server responds** through same connection

### Automatic Fallback

If WebSocket connection fails, Diffyne automatically falls back to AJAX:

```javascript
// Client automatically handles:
// 1. Try WebSocket connection
// 2. If fails, use AJAX
// 3. Retry WebSocket in background
```

## Switching Between Transports

### Runtime Switching

You can switch transports per-request or per-component:

```php
// In your component
public function mount(): void
{
    // Force AJAX for this component
    config(['diffyne.transport' => 'ajax']);
}
```

### Environment-Based

```php
// config/diffyne.php
'transport' => env('DIFFYNE_TRANSPORT', app()->environment('production') ? 'websocket' : 'ajax'),
```

## Performance Comparison

### Latency

| Operation | AJAX | WebSocket |
|-----------|------|-----------|
| Initial connection | ~50ms | ~10ms |
| Subsequent requests | ~50-200ms | ~10-50ms |
| Connection overhead | Per request | One-time |

### Throughput

| Metric | AJAX | WebSocket |
|--------|------|-----------|
| Requests/second | ~10-50 | ~100-1000 |
| Connection overhead | High | Low |
| Server resources | Lower | Higher |

### Use Cases

**AJAX is better for:**
- Standard CRUD operations
- Form submissions
- Occasional updates
- Lower server load

**WebSocket is better for:**
- Real-time chat
- Live notifications
- Dashboard updates
- Collaborative editing
- Live data feeds

## Monitoring

### Logs

WebSocket server logs to:

```
storage/logs/diffyne-websocket/
```

### Health Check

Check if WebSocket server is running:

```bash
curl http://127.0.0.1:6001/health
```

### Connection Status

Monitor connections in your application:

```php
// In your component or service
$wsStatus = cache()->get('diffyne:websocket:status', 'disconnected');
```

## Troubleshooting

### Connection Refused

**Problem**: `WebSocket connection failed`

**Solutions**:
1. Check if server is running: `ps aux | grep diffyne:websocket`
2. Verify port is open: `netstat -tuln | grep 6001`
3. Check firewall rules
4. Verify host/port in config

### CORS Errors

**Problem**: `CORS policy blocked`

**Solutions**:
1. Add your domain to `DIFFYNE_WS_CORS_ORIGINS`
2. Check CORS headers in response
3. Verify key is correct

### Authentication Failed

**Problem**: `WebSocket authentication failed`

**Solutions**:
1. Verify `DIFFYNE_WS_KEY` matches on client and server
2. Check key is set in `.env`
3. Clear config cache: `php artisan config:clear`

### High Memory Usage

**Problem**: WebSocket server using too much memory

**Solutions**:
1. Reduce connection timeout
2. Implement connection limits
3. Monitor and restart periodically
4. Use load balancer for multiple instances

## Best Practices

### 1. Use WebSocket Selectively

```php
// Use WebSocket for real-time components
class ChatRoom extends Component
{
    // WebSocket transport
}

// Use AJAX for standard components
class UserForm extends Component
{
    // AJAX transport
}
```

### 2. Handle Disconnections Gracefully

```php
public function hydrate(): void
{
    // Check WebSocket status
    if (! $this->isWebSocketConnected()) {
        // Fallback logic
    }
}
```

### 3. Monitor Connection Health

```php
// In your service provider
if (config('diffyne.transport') === 'websocket') {
    $this->app->singleton('diffyne.websocket.health', function () {
        return new WebSocketHealthChecker();
    });
}
```

### 4. Use Load Balancing

For high-traffic applications:

```nginx
upstream diffyne_websocket {
    server 127.0.0.1:6001;
    server 127.0.0.1:6002;
    server 127.0.0.1:6003;
}

server {
    location /diffyne {
        proxy_pass http://diffyne_websocket;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### 5. Secure Your WebSocket

```php
// Use authentication
'websocket' => [
    'key' => env('DIFFYNE_WS_KEY'), // Strong, random key
    'cors' => [
        'allowed_origins' => [
            'https://yourdomain.com',
            'https://www.yourdomain.com',
        ],
    ],
],
```

## Example: Real-Time Chat

```php
class ChatRoom extends Component
{
    public array $messages = [];
    public string $newMessage = '';
    
    public function mount(): void
    {
        $this->loadMessages();
    }
    
    #[Invokable]
    public function sendMessage(): void
    {
        $this->validate([
            'newMessage' => 'required|string|max:500',
        ]);
        
        Message::create([
            'user_id' => auth()->id(),
            'content' => $this->newMessage,
            'room_id' => $this->roomId,
        ]);
        
        $this->newMessage = '';
        $this->loadMessages();
        
        // Broadcast to all connected clients
        $this->dispatch('message-sent', [
            'room_id' => $this->roomId,
        ]);
    }
    
    #[On('message-sent')]
    public function handleNewMessage(array $data): void
    {
        if ($data['room_id'] === $this->roomId) {
            $this->loadMessages();
        }
    }
}
```

## Migration from AJAX

### Step 1: Test Locally

```env
DIFFYNE_TRANSPORT=websocket
```

### Step 2: Monitor Performance

Watch for:
- Connection stability
- Memory usage
- Response times
- Error rates

### Step 3: Deploy Gradually

1. Deploy to staging
2. Test thoroughly
3. Deploy to production
4. Monitor closely

### Step 4: Rollback Plan

Keep AJAX as fallback:

```php
'transport' => env('DIFFYNE_TRANSPORT', 'ajax'),
```

If issues occur, simply change `.env`:

```env
DIFFYNE_TRANSPORT=ajax
```

## Next Steps

- [Installation](getting-started/installation.md) - Setup instructions
- [Component Events](features/component-events.md) - Event system
- [Performance](performance.md) - Optimization tips
- [Sockeon Documentation](https://sockeon.com/docs) - WebSocket server docs

