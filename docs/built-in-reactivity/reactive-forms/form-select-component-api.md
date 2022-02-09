# Select Component API

The `form_select` component is Vue.js driven child component of the `matestack_form` component and is used to collect user input.

```ruby
matestack_form my_form_config do
  form_select key: :status, options: { 'active': 1, 'deactive': 0 }, #...
end
```

All child components `form_*` \(including this component\) have to be placed within the scope of the parent `form` component, without any other Vue.js driven component like `toggle`, `async` creating a new scope between the child component and the parent form component! Non-Vue.js component can be placed between `form` and `form_*` without issues!

```ruby
# that's working:
matestack_form some_form_config do
  form_* key: :foo
  toggle show_on: "some-event" do
    plain "hello!"
  end
end

# that's not working:
matestack_form some_form_config do
  toggle show_on: "some-event" do
    form_* key: :foo
  end
end
```

## Parameters

### key - required

Defines the key which should be used when posting the form data to the server.

### options - required

Can either be an Array or Hash:

**Array usage**

```ruby
matestack_form my_form_config do
  form_select key: :status, options: [0, 1]
end
```

will render:

```markup
<select>
  <option value="0">0</option>
  <option value="1">1</option>
</select>
```

**Hash usage**

```ruby
matestack_form my_form_config do
  form_select key: :status, options: { 'active': 1, 'deactive': 0 }
end
```

will render:

```markup
<select>
  <option value="0">deactive</option>
  <option value="1">active</option>
</select>
```

The hash values will be used as values for the options, the keys as displayed values.

**ActiveRecord Enum Mapping**

If you want to use ActiveRecord enums as options for your select input, you can use the enum class method:

```ruby
class Conversation < ActiveRecord::Base
  enum status: { active: 0, archived: 1 }
end
```

```ruby
matestack_form my_form_config do
  form_select key: :status, options: Conversation.statuses
end
```

### disabled\_values

Defines which options \(by value\) should be disabled. Pass in as Array.

```ruby
matestack_form my_form_config do
  form_select key: :status, options: [1,2,3], disabled_values: [1, 2]
end
```

or

```ruby
matestack_form my_form_config do
  form_select key: :status, options: { 'active': 1, 'deactive': 0 }, disabled_values: [1]
end
```

### multiple

If set to true, a native HTML multiple select will be rendered. Selected values will be posted as an Array to the server.

### init

Defines the init value of the select input. If mapped to an ActiveRecord model, the init value will be derived automatically from the model instance.

**when multiple is set to true**

Pass in an Array of init values:

```ruby
matestack_form my_form_config do
  form_select key: :status, [1,2,3], multiple: true, init: [1,2]
end
```

**when multiple is set to false/not specified**

Pass in an Integer:

```ruby
matestack_form my_form_config do
  form_select key: :status, [1,2,3], init: 1
end
```

### placeholder

Defines the placeholder which will be rendered as first, disabled option.

### label

Defines the label which will be rendered right before the textarea tag. You can also use the `label` component in order to create more complex label structures.

## Custom Select

If you want to create your own select component, that's easily done since `v.1.3.0`. Imagine, you want to use `select2.js` and therefore need to adjust the `select` rendering and need to initialize the third party library:

* Create your own Ruby component:

`app/matestack/components/my_form_select.rb`

```ruby
class Components::MyFormSelect < Matestack::Ui::VueJs::Components::Form::Select

  vue_name "my-form-select"

  # optionally add some data here, which will be accessible within your Vue.js component
  def vue_props
    {
      foo: "bar"
    }
  end

  def response
    # exactly one root element is required since this is a Vue.js component template
    div do
      label text: "my select input"
      select select_attributes.merge(class: "select2") do
        render_options
      end
      render_errors
    end
  end

end
```

* Create the corresponding Vue.js component:

Generic code:

```javascript
const myFormSelect = {
  mixins: [MatestackUiVueJs.componentMixin, MatestackUiVueJs.formSelectMixin],
  template: MatestackUiVueJs.componentHelpers.inlineTemplate,
  data() {
    return {};
  },
  methods: {
    afterInitialize: function(value){
      // optional: if you need to modify the initial value
      // use this.setValue(xyz) in order to change the value
      // this method can be used in other methods or mounted hook of this component as well!
      this.setValue(xyz)
    }
  },
  mounted: function(){
    // use/initialize any third party library here
    // you can access the default initial value via this.componentConfig["init_value"]
    // if you need to, you can access your own component config data which added
    // within the prepare method of the corresponding Ruby class
    // this.props["foo"] would be "bar" in this case
  }
}
export default myFormSelect

// and register in your application js file like:
appInstance.component('my-form-select', myFormSelect) // register at appInstance
```

In order to support the `select2.js` library, you would do something like this:

`app/matestack/componenst/my_form_select.js`

```javascript
const myFormSelect = {
  mixins: [MatestackUiVueJs.componentMixin, MatestackUiVueJs.formSelectMixin],
  template: MatestackUiVueJs.componentHelpers.inlineTemplate,
  data() {
    return {};
  },
  methods: {
    afterInitialize: function(value){
      $('.select2').val(value).trigger("change");
    }
  },
  mounted: function(){
    const self = this;
    //activate
    $('.select2').select2();

    //handle change event
    $('.select2').on('select2:select', function (e) {
      self.setValue(e.params.data.id)
    });
  }
}
export default myFormSelect

// and register in your application js file like:
appInstance.component('my-form-select', myFormSelect) // register at appInstance
```

* Don't forget to require and register the custom component JavaScript according to your JS setup!
* Finally, use it within a `matestack_form`:

```ruby
matestack_form some_form_config do
  Components::MyFormSelect.call(key: :foo, options: [1,2,3])
end
```
