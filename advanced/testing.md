# Testing Diffyne Components

Guide to testing your Diffyne components.

## Setup

Diffyne components are standard PHP classes, so you can test them like any Laravel class.

```php
use Tests\TestCase;
use App\Diffyne\Counter;

class CounterTest extends TestCase
{
    /** @test */
    public function it_increments_count()
    {
        $component = new Counter();
        
        $component->increment();
        
        $this->assertEquals(1, $component->count);
    }
}
```

## Testing Component Methods

```php
/** @test */
public function it_adds_todo()
{
    $component = new TodoList();
    $component->newTodo = 'Buy milk';
    
    $component->addTodo();
    
    $this->assertCount(1, $component->todos);
    $this->assertEquals('Buy milk', $component->todos[0]['text']);
    $this->assertEquals('', $component->newTodo);
}

/** @test */
public function it_removes_todo()
{
    $component = new TodoList();
    $component->todos = [
        ['text' => 'Task 1', 'completed' => false],
        ['text' => 'Task 2', 'completed' => false],
    ];
    
    $component->removeTodo(0);
    
    $this->assertCount(1, $component->todos);
    $this->assertEquals('Task 2', $component->todos[0]['text']);
}
```

## Testing Validation

```php
use Illuminate\Validation\ValidationException;

/** @test */
public function it_validates_required_fields()
{
    $component = new ContactForm();
    
    $this->expectException(ValidationException::class);
    
    $component->submit();
}

/** @test */
public function it_validates_email_format()
{
    $component = new ContactForm();
    $component->name = 'John';
    $component->email = 'invalid-email';
    $component->message = 'Hello world';
    
    try {
        $component->submit();
        $this->fail('Expected ValidationException');
    } catch (ValidationException $e) {
        $this->assertTrue($e->validator->errors()->has('email'));
    }
}

/** @test */
public function it_submits_valid_form()
{
    $component = new ContactForm();
    $component->name = 'John Doe';
    $component->email = 'john@example.com';
    $component->message = 'Hello world!';
    
    $component->submit();
    
    $this->assertTrue($component->submitted);
}
```

## Testing Lifecycle Hooks

```php
/** @test */
public function mount_loads_initial_data()
{
    $component = new ProductList();
    
    $component->mount('electronics');
    
    $this->assertEquals('electronics', $component->category);
    $this->assertNotEmpty($component->products);
}

/** @test */
public function updated_hook_triggers_search()
{
    $component = new Search();
    
    $component->query = 'laptop';
    $component->updated('query');
    
    $this->assertNotEmpty($component->results);
}
```

## Testing with Database

```php
use Illuminate\Foundation\Testing\RefreshDatabase;

class TodoListTest extends TestCase
{
    use RefreshDatabase;
    
    /** @test */
    public function it_loads_todos_from_database()
    {
        Todo::factory()->count(3)->create(['user_id' => 1]);
        
        $component = new TodoList();
        $component->mount();
        
        $this->assertCount(3, $component->todos);
    }
}
```

## Next Steps

- [Component State](component-state.md) - Understanding state
- [Lifecycle Hooks](lifecycle-hooks.md) - Hook behavior
- [Performance](performance.md) - Optimization
