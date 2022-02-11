# Async Component API

The `async` component enables us to rerender/defer parts of the UI based on events/timing without full page reload.

Please be aware that, if not configured otherwise, the `async` core component does get loaded and displayed on initial pageload!

## Parameters

The `async` core component accepts the following parameters:

### ID - required

The `async` component needs an ID in order to resolve the correct content on an async HTTP request

```ruby
async id: "some-unique-id" do
  #...
end
```

### Rerender\_on

The `rerender_on` option lets us define an event on which the component gets rerendered.

```ruby
async rerender_on: 'my_event', id: "some-unique-id" do
  div id: 'my-div' do
    plain "#{DateTime.now.strftime('%Q')}"
  end
end
```

**Note:** The `rerender_on` option lets you rerender parts of your UI asynchronously. But please consider that, if not configured differently, it

a) is **not** _lazily loaded_ and

b) and does get displayed on initial pageload

by default.

Lazy (or defered) loading can be configured like shown [here](async-component-api.md#defer).

You can pass in multiple, comma-separated events on which the component should rerender.

```ruby
async rerender_on: 'my_event, some_other_event', id: "some-unique-id"
```

### Defer

The `defer` option may be used in two ways:

#### simple defer

`defer: true` implies that the content of the `async` component gets requested within a separate GET request right after initial page load is done.

```ruby
async defer: true, id: "some-unique-id"do
  div id: 'my-div' do
    plain 'I will be requested within a separate GET request right after initial page load is done'
  end
end
```

#### delayed defer

`defer: 2000` means that the content of the `async` component gets requested within a separate GET request 2000 milliseconds after initial page load is done.

```ruby
async defer: 2000, id: "some-unique-id" do
  div id: 'my-div' do
    plain 'I will be requested within a separate GET request 2000ms after initial page load is done'
  end
end
```

The content of an `async` component with activated `defer` behavior is not resolved within the first page load!

```ruby
#...
async defer: 1000, id: "some-unique-id" do
  some_database_data = SomeModel.some_heavy_query
  div id: 'my-div' do
    some_database_data.each do |some_instance|
      plain some_instance.id
    end
  end
end
async defer: 2000, id: "some-unique-id" do
  some_other_database_data = SomeModel.some_other_heavy_query
  div id: 'my-div' do
    some_other_database_data.each do |some_instance|
      plain some_instance.id
    end
  end
end
#...
```

The `SomeModel.some_query` does not get executed within the first page load and only will be called within the deferred GET request. This helps us to render a complex UI with loads of heavy method calls step by step without slowing down the initial page load and rendering of simple content.

## DOM structure, loading state and animations

Async components will be wrapped by a DOM structure like this:

```markup
<div class="matestack-async-component-container">
  <div class="matestack-async-component-wrapper">
    <div class="matestack-async-component-root" >
      hello!
    </div>
  </div>
</div>
```

During async rendering a `loading` class will automatically be applied, which can be used for CSS styling and animations:

```markup
<div class="matestack-async-component-container loading">
  <div class="matestack-async-component-wrapper loading">
    <div class="matestack-async-component-root" >
      hello!
    </div>
  </div>
</div>
```

## Examples

### Deferring content

You can either configure an `async` component to request its content directly after the page load or to delay the request for a given amount of time after the page load. `:defer` expects either a boolean or a integer representing the delay time in milliseconds. If `:defer` is set to `false` the `async` component will be rendered on page load and not deferred. If set to `true` it will request its content directly after the page load.

```ruby
def response
  async id: 'deferred-async', defer: true do
    plain 'Some content rendered after page is loaded.'
  end
end
```

The above `async` component will be rendered asynchronously after page load.

```ruby
def response
  async id: 'delayed-deferred-async', defer: 500 do
    plain 'Some delayed deferred content'
  end
end
```

Specifying `defer: 500` will delay the asynchronous request after page load of the `async` component for 300ms and render the content afterwards.

### Rerendering content

The `async` leverages the event hub and can react to emitted events. If it receives one or more of the with `:rerender_on` specified events it will asynchronously request a rerender of its content. The response will only include the rerendered html of the `async` component which then replaces the current content of the `async`. If you specify multiple events in `:rerender_on` they need to be seperated by a comma.

```ruby
def response
  async id: 'rerendering-async', rerender_on: 'update-time' do
    paragraph DateTime.now
  end
  onclick emit: 'update-time' do
    button text: 'Update time'
  end
end
```

The above snippet renders a paragraph with the current time and a button "Update time" on page load. If the button is clicked a _update-time_ event is emitted. The `async` component wrapping the paragraph receives the event and reacts to it by requesting its rerendered content from the server and replacing its content with the received html. In this case it will rerender after button click and show the updated time.
