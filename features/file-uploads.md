# File Uploads

Diffyne provides a simple, Livewire-like file upload system with temporary file storage and easy-to-use methods.

## Overview

The file upload feature allows you to:
- Upload files temporarily before form submission
- Preview uploaded files before saving
- Preserve original filenames (stored automatically with each upload)
- Move files to permanent storage when ready (with option to use original filename)
- Automatically clean up old temporary files

## Basic File Upload

### Component

```php
use Diffyne\Attributes\Invokable;

class ProductForm extends Component
{
    public ?string $image = null;
    public bool $showAddImageModal = false;

    #[Invokable]
    public function addImage(): void
    {
        if ($this->image) {
            // Move temporary file to permanent storage
            // Option 1: Use original filename
            $imagePath = $this->moveTemporaryFile(
                $this->image,
                'products/' . $this->productId . '/',
                'public',
                true  // Use original filename
            );

            // Option 2: Use custom filename
            // $extension = pathinfo($this->image, PATHINFO_EXTENSION) ?: 'jpg';
            // $filename = uniqid() . '.' . $extension;
            // $imagePath = $this->moveTemporaryFile(
            //     $this->image,
            //     'products/' . $this->productId . '/' . $filename,
            //     'public'
            // );

            if ($imagePath) {
                ProductImage::create([
                    'image_path' => $imagePath,
                    'product_id' => $this->productId,
                ]);

                $this->showAddImageModal = false;
                $this->image = null;
            }
        }
    }
}
```

### View

```blade
<div>
    <input 
        type="file" 
        diff:model="image"
        accept="image/*">
    
    @if($image)
        <img 
            src="{{ $component->getTemporaryFilePreviewUrl($image) }}" 
            alt="Preview"
            class="w-32 h-32 object-cover">
    @endif
    
    <button diff:click="addImage">Save Image</button>
</div>
```

## How It Works

1. **User selects file**: The file is automatically uploaded to temporary storage
2. **Component receives identifier**: The `image` property contains a temporary file identifier (e.g., `"diffyne-abc123:filename.jpg"`)
3. **Preview available**: Use `getTemporaryFilePreviewUrl()` to show a preview
4. **Move to permanent**: Call `moveTemporaryFile()` when ready to save

## Multiple File Uploads

### Component

```php
use Diffyne\Attributes\Invokable;

class GalleryForm extends Component
{
    public array $images = [];

    #[Invokable]
    public function saveGallery(): void
    {
        foreach ($this->images as $identifier) {
            $imagePath = $this->moveTemporaryFile(
                $identifier,
                'gallery/' . uniqid() . '.jpg',
                'public'
            );

            if ($imagePath) {
                GalleryImage::create([
                    'image_path' => $imagePath,
                ]);
            }
        }

        // Clean up temporary files
        $this->cleanupTemporaryFiles();
    }
}
```

### View

```blade
<div>
    <input 
        type="file" 
        diff:model="images"
        multiple
        accept="image/*">
    
    <div class="grid grid-cols-3 gap-4">
        @foreach($images as $image)
            <img 
                src="{{ $component->getTemporaryFilePreviewUrl($image) }}" 
                alt="Preview"
                class="w-full h-32 object-cover">
        @endforeach
    </div>
    
    <button diff:click="saveGallery">Save Gallery</button>
</div>
```

## Available Methods

### `moveTemporaryFile()`

Move a temporary file to permanent storage:

```php
$permanentPath = $this->moveTemporaryFile(
    string $identifier,        // Temporary file identifier
    string $destinationPath,   // Destination path (e.g., 'avatars/user-123.jpg')
    ?string $disk = null,      // Storage disk (defaults to config)
    bool $useOriginalName = false // If true, uses original filename instead of destinationPath filename
);
```

**Returns:** Permanent file path or `null` on failure

**Example:**
```php
// Use custom filename
$imagePath = $this->moveTemporaryFile(
    $this->avatar,
    'avatars/' . auth()->id() . '.jpg',
    'public'
);

// Use original filename
$imagePath = $this->moveTemporaryFile(
    $this->avatar,
    'avatars/',  // Directory only
    'public',
    true  // Use original filename
);
// Result: 'avatars/original-filename.jpg'
```

### `getTemporaryFilePreviewUrl()`

Get a preview URL for a temporary file:

```php
$previewUrl = $this->getTemporaryFilePreviewUrl(string $identifier);
```

**Returns:** URL to preview the temporary file

**Example:**
```blade
<img src="{{ $component->getTemporaryFilePreviewUrl($image) }}" alt="Preview">
```

### `getTemporaryFileOriginalName()`

Get the original filename for a temporary file:

```php
$originalName = $this->getTemporaryFileOriginalName(string $identifier);
```

**Returns:** Original filename or `null` if not found

**Example:**
```php
$originalName = $this->getTemporaryFileOriginalName($this->image);
// Returns: "my-document.pdf" or null
```

### `deleteTemporaryFile()`

Delete a temporary file:

```php
$deleted = $this->deleteTemporaryFile(string $identifier);
```

**Returns:** `true` if deleted, `false` otherwise

**Example:**
```php
if ($this->image) {
    $this->deleteTemporaryFile($this->image);
    $this->image = null;
}
```

### `cleanupTemporaryFiles()`

Clean up all old temporary files (static method):

```php
$deletedCount = \Diffyne\Component::cleanupTemporaryFiles();
```

**Returns:** Number of files deleted

**Note:** This is typically run via the scheduled command, but can be called programmatically.

## Configuration

Configure file uploads in `config/diffyne.php`:

```php
'file_upload' => [
    // Storage disk for temporary files
    'disk' => env('DIFFYNE_FILE_DISK', 'local'),

    // Path for temporary file storage (relative to disk root)
    'temporary_path' => env('DIFFYNE_FILE_TEMP_PATH', 'diffyne/temp'),

    // Maximum file size in KB (default: 12MB)
    'max_size' => env('DIFFYNE_FILE_MAX_SIZE', 12288),

    // Allowed MIME types (null = all types allowed)
    // Example: ['image/jpeg', 'image/png', 'image/gif']
    'allowed_mimes' => env('DIFFYNE_FILE_MIMES') ? explode(',', env('DIFFYNE_FILE_MIMES')) : null,

    // Cleanup temporary files older than this many hours
    'cleanup_after_hours' => env('DIFFYNE_FILE_CLEANUP_HOURS', 24),
],
```

### Environment Variables

Add these to your `.env` file:

```bash
# File upload disk
DIFFYNE_FILE_DISK=local

# Temporary file path
DIFFYNE_FILE_TEMP_PATH=diffyne/temp

# Maximum file size in KB (12MB = 12288)
DIFFYNE_FILE_MAX_SIZE=12288

# Allowed MIME types (comma-separated)
DIFFYNE_FILE_MIMES=image/jpeg,image/png,image/gif

# Cleanup files older than 24 hours
DIFFYNE_FILE_CLEANUP_HOURS=24
```

## Automatic Cleanup

Diffyne automatically cleans up old temporary files daily via a scheduled task. The cleanup runs based on the `cleanup_after_hours` configuration.

### Manual Cleanup

You can also run cleanup manually:

```bash
php artisan diffyne:cleanup-files
```

### Programmatic Cleanup

```php
use Diffyne\Component;

$deletedCount = Component::cleanupTemporaryFiles();
```

## Validation

### File Size Validation

Files are automatically validated against `max_size` configuration. If a file exceeds the limit, the upload will fail with a `422` error.

### MIME Type Validation

If `allowed_mimes` is configured, only files with matching MIME types are allowed:

```php
// config/diffyne.php
'allowed_mimes' => ['image/jpeg', 'image/png', 'image/gif'],
```

If a file doesn't match the allowed MIME types, the upload will fail with a `422` error.

## Complete Example

### Component

```php
use App\Models\Product;
use App\Models\ProductImage;
use Diffyne\Attributes\Invokable;

class ProductImageUpload extends Component
{
    public int $productId;
    public array $images = [];
    public bool $showModal = false;

    public function mount(int $productId): void
    {
        $this->productId = $productId;
    }

    #[Invokable]
    public function openModal(): void
    {
        $this->showModal = true;
    }

    #[Invokable]
    public function closeModal(): void
    {
        $this->showModal = false;
        $this->images = [];
    }

    #[Invokable]
    public function saveImages(): void
    {
        foreach ($this->images as $identifier) {
            $extension = pathinfo($identifier, PATHINFO_EXTENSION) ?: 'jpg';
            $filename = uniqid() . '.' . $extension;
            
            $imagePath = $this->moveTemporaryFile(
                $identifier,
                'products/' . $this->productId . '/' . $filename,
                'public'
            );

            if ($imagePath) {
                ProductImage::create([
                    'image_path' => $imagePath,
                    'product_id' => $this->productId,
                ]);
            }
        }

        $this->closeModal();
        $this->dispatch('images-saved');
    }
}
```

### View

```blade
<div>
    <button diff:click="openModal">Add Images</button>

    @if($showModal)
        <div class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center">
            <div class="bg-white p-6 rounded-lg max-w-2xl w-full">
                <h2 class="text-xl font-bold mb-4">Upload Product Images</h2>

                <input 
                    type="file" 
                    diff:model="images"
                    multiple
                    accept="image/*"
                    class="mb-4">

                @if(count($images) > 0)
                    <div class="grid grid-cols-3 gap-4 mb-4">
                        @foreach($images as $image)
                            <div class="relative">
                                <img 
                                    src="{{ $component->getTemporaryFilePreviewUrl($image) }}" 
                                    alt="Preview"
                                    class="w-full h-32 object-cover rounded">
                            </div>
                        @endforeach
                    </div>
                @endif

                <div class="flex gap-2">
                    <button 
                        diff:click="saveImages"
                        class="bg-blue-500 text-white px-4 py-2 rounded">
                        Save
                    </button>
                    <button 
                        diff:click="closeModal"
                        class="bg-gray-500 text-white px-4 py-2 rounded">
                        Cancel
                    </button>
                </div>
            </div>
        </div>
    @endif
</div>
```

## Best Practices

### 1. Always Move Files to Permanent Storage

```php
// ✅ Good - move to permanent storage
$path = $this->moveTemporaryFile($this->image, 'avatars/user.jpg', 'public');

// ❌ Bad - temporary files will be cleaned up
// Don't use the identifier directly in your database
```

### 2. Generate Unique Filenames or Use Original Names

```php
// ✅ Good - unique filename
$extension = pathinfo($identifier, PATHINFO_EXTENSION) ?: 'jpg';
$filename = uniqid() . '.' . $extension;
$path = $this->moveTemporaryFile($identifier, "uploads/{$filename}", 'public');

// ✅ Good - use original filename (preserves user's filename)
$path = $this->moveTemporaryFile($identifier, 'uploads/', 'public', true);

// ❌ Bad - may overwrite existing files if using original name without directory
$path = $this->moveTemporaryFile($identifier, 'uploads/image.jpg', 'public', true);
```

### 3. Clean Up After Use

```php
// ✅ Good - clean up after moving
foreach ($this->images as $identifier) {
    $path = $this->moveTemporaryFile($identifier, $destination, 'public');
    // File is automatically deleted from temp storage
}
```

### 4. Validate File Types

```php
// Configure allowed MIME types in config
'allowed_mimes' => ['image/jpeg', 'image/png', 'image/gif'],
```

### 5. Set Appropriate File Size Limits

```php
// config/diffyne.php
'max_size' => 5120, // 5MB for images
// or
'max_size' => 51200, // 50MB for documents
```

## Troubleshooting

### Files Not Uploading

1. Check file size is within `max_size` limit
2. Verify MIME type is allowed (if `allowed_mimes` is configured)
3. Check storage disk permissions
4. Verify temporary path exists and is writable

### Preview Not Showing

1. Ensure you're using `getTemporaryFilePreviewUrl()` method
2. Check the preview route is accessible
3. Verify file exists in temporary storage

### Files Being Deleted

1. Temporary files are automatically cleaned up after `cleanup_after_hours`
2. Always move files to permanent storage before cleanup runs
3. Increase `cleanup_after_hours` if needed

## Next Steps

Learn more about file handling:

- [Forms](/features/forms) - Integrate file uploads with forms
- [Validation](/features/validation) - Validate file uploads
- [Configuration](/getting-started/installation) - Configure file upload settings

