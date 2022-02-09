# Isolated Component API

## Authorize

When asynchronously rendering isolated components, these HTTP calls are actually processed by the controller action responsible for the corresponding page rendering. One might think, that the optional authorization and authentication rules of that controller action should therefore be enough for securing isolated component rendering.

But that's not true. It would be possible to hijack public controller actions without any authorization in place and request isolated components which are only meant to be rendered within a secured context.

That's why we enforce the usage of the `authorized?` method to make sure, all isolated components take care of their authorization themselves.

If `authorized?` returns `true`, the component will be rendered. If it returns `false`, the component will not be rendered.

A public isolated component therefore needs an `authorized?` method simply returning `true`.

You can create your own isolated base components with their `authorized` methods for your use cases and thus keep your code DRY.

## Options

All options below are meant to be injected to your isolated component like:

```ruby
class Home < Matestack::Ui::Page
  def response
    heading size: 1, text: 'Welcome'
    my_isolated defer: 1000, #...
  end
end
```

### defer

The option defer lets you delay the initial component rendering. If you set defer to a positive integer or `true` the isolate component will not be rendered on initial page load. Instead it will be rendered with an asynchronous request only resolving the isolate component.

If `defer` is set to `true` the asynchronous requests gets triggered as soon as the initial page is loaded.

If `defer` is set to a positive integer \(including zero\) the asynchronous request is delayed by the given amount in ms.

### rerender\_on

The `rerender_on` options lets you define events on which the component will be rerenderd asynchronously. Events on which the component should be rerendered are specified via a comma seperated string, for example `rerender_on: 'event_one, event_two`.

### rerender\_delay

The `rerender_delay` option lets you specify a delay in ms after which the asynchronous request is emitted to rerender the component. It can for example be used to smooth out loading animations, preventing flickering in the UI for fast responses.

### init\_on

With `init_on` you can specify events on which the isolate components gets initialized. Specify events on which the component should be initially rendered via a comma seperated string. When receiving a matching event the isolate component is rendered asynchronously. If you also specified the `defer` option the asynchronous rerendering call will be delayed by the given time in ms of the defer option. If `defer` is set to `true` the rendering will not be delayed.

### public\_options

You can pass data as a hash to your custom isolate component with the `public_options` option. This data is inside the isolate component accessible via a hash with indifferent access, for example `public_options[:item_id]`. All data contained in the `public_options` will be passed as json to the corresponding Vue.js component, which means this data is visible on the client side as it is rendered in the Vue.js component config. So be careful what data you pass into `public_options`!

Due to the isolation of the component the data needs to be stored on the client side as to encapsulate the component from the rest of the UI. For example: You want to render a collection of models in single components which should be able to rerender asynchronously without rerendering the whole UI. Since we do not rerender the whole UI there is no way the component can know which of the models it should rerender. Therefore passing for example the id in the public\_options hash gives you the possibility to access the id in an async request and fetch the model again for rerendering. See below for examples.

## DOM structure, loading state and animations

Isolated components will be wrapped by a DOM structure like this:

```markup
<div class="matestack-isolated-component-container">
  <div class="matestack-isolated-component-wrapper">
    <div class="matestack-isolated-component-root" >
      hello!
    </div>
  </div>
</div>
```

During async rendering a `loading` class will automatically be applied, which can be used for CSS styling and animations:

```markup
<div class="matestack-isolated-component-container loading">
  <div class="matestack-isolated-component-wrapper loading">
    <div class="matestack-isolated-component-root" >
      hello!
    </div>
  </div>
</div>
```

Additionally you can define a `loading_state_element` within the component class like:

```ruby
class MyIsolated < Matestack::Ui::IsolatedComponent
  def response
    div id: 'my-isolated-wrapper' do
      plain I18n.l(DateTime.now)
    end
  end

  def authorized?
    true
  end

  def loading_state_element
    div class: "loading-spinner" do
      plain "spinner..."
    end
  end
end
```

which will then render to:

```markup
<div class="matestack-isolated-component-container">
  <div class="loading-state-element-wrapper">
    <div class="loading-spinner">
      spinner...
    </div>
  </div>
  <div class="matestack-isolated-component-wrapper">
    <div class="matestack-isolated-component-root" >
      hello!
    </div>
  </div>
</div>
```

and during async rendering request:

```markup
<div class="matestack-isolated-component-container loading">
  <div class="loading-state-element-wrapper loading">
    <div class="loading-spinner">
      spinner...
    </div>
  </div>
  <div class="matestack-isolated-component-wrapper loading">
    <div class="matestack-isolated-component-root" >
      hello!
    </div>
  </div>
</div>
```

## Examples

### Simple Isolate

Create a custom component inheriting from the isolate component

```ruby
class MyIsolated < Matestack::Ui::IsolatedComponent

  def response
    div id: 'my-isolated-wrapper' do
      plain I18n.l(DateTime.now)
    end
  end

  def authorized?
    true
    # check access here using current_user for example when using Devise
    # true means, this isolated component is public
  end

end
```

And use it on your page

```ruby
class Home < Matestack::Ui::Page

  def response
    h1 'Welcome'
    MyIsolated.call()
  end

end
```

This will render a h1 with the content welcome and the localized current datetime inside the isolated component. The isolated component gets rendered with the initial page load, because the defer options is not set.

### Simple Deferred Isolated

```ruby
class Home < Matestack::Ui::Page

  def response
    h1 'Welcome'
    MyIsolated.call(defer: true)
    MyIsolated.call(defer: 2000)
  end

end
```

By specifying the `defer` option both calls to the custom isolated components will not get rendered on initial page load. Instead the component with `defer: true` will get rendered as soon as the initial page load is done and the component with `defer: 2000` will be rendered 2000ms after the initial page load is done. Which means that the second my\_isolated component will show the datetime with 2s more on the clock then the first one.

### Rerender On Isolate Component

```ruby
class Home < Matestack::Ui::Page

  def response
    h1 'Welcome'
    MyIsolated.call(rerender_on: 'update_time')
    onclick emit: 'update_time' do
      button 'Update Time!'
    end
  end

end
```

`rerender_on: 'update_time'` tells the custom isolated component to rerender its content asynchronously whenever the event `update_time` is emitted. In this case every time the button is pressed the event is emitted and the isolated component gets rerendered, showing the new timestamp afterwards. In contrast to async components only the `MyIsolated` component is rendered on the server side instead of the whole UI.

### Rerender Isolated Component with a delay

```ruby
class Home < Matestack::Ui::Page

  def response
    h1 'Welcome'
    MyIsolated.call(rerender_on: 'update_time', rerender_delay: 300)
    onclick emit: 'update_time' do
      button 'Update Time!'
    end
  end

end
```

The `MyIsolated` component will be rerendered 300ms after the `update_time` event is emitted

### Initialize isolated component on a event

```ruby
class Home < Matestack::Ui::Page

  def response
   h1 'Welcome'
    MyIsolated.call(init_on: 'init_time')
    onclick emit: 'init_time' do
      button 'Init Time!'
    end
  end

end
```

With `init_on: 'init_time'` you can specify an event on which the isolated component should be initialized. When you click the button the event `init_time` is emitted and the isolated component asynchronously requests its content.

### Use custom data in isolated components

Like described above it is possible to use custom data in your isolated components. Just pass them as a hash to `public_options` and use them in your isolated component. Be careful, because `public_options` are visible in the raw html response from the server as they get passed to a Vue.js component.

Lets render a collection of models and each of them should rerender when a user clicks a corresponding refresh button. Our model is called `Match`, representing a soccer match. It has an attribute called score with the current match score.

At first we create a custom isolated component.

```ruby
class Components::Match::IsolatedScore < Matestack::Ui::IsolatedComponent

  def prepare
    @match = Match.find_by(public_options[:id])
  end

  def response
    div class: 'score' do
      plain @match.score
    end
    onclick emit: "update_match_#{@match.id}" do
      button 'Refresh'
    end
  end

  def authorized?
    true
    # check access here using current_user for example when using Devise
    # true means, this isolated component is public
  end

end
```

Now we create our page which will render a list of matches.

```ruby
class Match::Pages::Index < Matestack::Ui::Page

  def response
    Match.all.each do |match|
      Components::Match::IsolatedScore.call(public_options: { id: match.id }, rerender_on: "update_match_#{match.id}")
    end
  end

end
```

This page will render a match\_isolated\_score component for each match. If one of the isolated components gets rerendered we need the id in order to fetch the correct match. Because the server only resolves the isolated component instead of the whole UI it does not know which match exactly is requested unless the client requests a rerender with the match id. This is why `public_options` options are passed to the client side Vue.js component. So if match two should be rerendered the client requests the match\_isolated\_score component with `public_options: { id: 2 }`. With this information our isolated component can fetch the match and rerender itself.

