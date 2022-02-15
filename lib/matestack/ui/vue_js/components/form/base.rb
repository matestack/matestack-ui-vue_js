module Matestack
  module Ui
    module VueJs
      module Components
        module Form
          class Base < Matestack::Ui::VueJs::Vue

            optional :key, :type, :label, :init, :errors, :id, :multiple, :placeholder

            def form_context
              Matestack::Ui::VueJs::Components::Form::Context.form_context
            end

            def component_attributes
              super.merge("matestack-ui-vuejs-ref": "#{form_context.component_uid}-#{component_id}")
            end

            def component_id
              # defined in subclass
            end

            # options/settings

            def key
              ctx.key
            end

            def type
              ctx.type
            end

            def input_label
              ctx.label
            end

            def init
              ctx.init
            end

            def error_config
              ctx.errors
            end

            def id
              if ctx.id.present?
                "'#{ctx.id}'"
              else
                if form_context.is_nested_form?
                  "'#{key}'+vc.parentNestedFormRuntimeId"
                else
                  "'#{key}'"
                end
              end
            end

            def multiple
              ctx.multiple
            end

            def placeholder
              ctx.placeholder
            end

            # calculated attributes

            def attributes
              (options || {}).merge({
                "matestack-ui-vuejs-ref": matestack_ui_vuejs_ref("input.#{attribute_key}"),
                ":id": id,
                type: ctx.type,
                multiple: ctx.multiple,
                placeholder: ctx.placeholder,
                'v-on:change': change_event,
                'init-value': init_value,
                'v-bind:class': "{ '#{input_error_class}': #{error_key} }",
              }).tap do |attrs|
                attrs[:"#{v_model_type}"] = input_key unless type == :file
              end
            end

            def attribute_key
              key.to_s + "#{'[]' if ctx.multiple && ctx.type == :file}"
            end

            def name
              attribute_key
            end

            def init_value
              return init unless init.nil?
              if form_context.for_option.respond_to?(key)
                form_context.for_option.send(key)
              end
            end

            def change_event
              input_changed = "vc.inputChanged('#{attribute_key}');"
              input_changed << "vc.filesAdded('#{attribute_key}');" if type == :file
              input_changed
            end

            def input_key
              "vc.parentFormData['#{key}']"
            end

            # set v-model.number for all numeric init values or options
            def v_model_type(item=nil)
              if item.nil?
                (type == :number || init_value.is_a?(Numeric)) ? 'v-model.number' : 'v-model'
              else
                item.is_a?(Integer) ? 'v-model.number' : 'v-model'
              end
            end

            # set value-type "Integer" for all numeric init values or options
            def value_type(item=nil)
              if item.nil?
                (type == :number || init_value.is_a?(Numeric)) ? Integer : nil
              else
                item.is_a?(Integer)? Integer : nil
              end
            end

            # error rendering

            def display_errors?
              if form_context.ctx.errors == false
                error_config ? true : false
              else
                error_config != false
              end
            end

            def error_key
              "vc.parentFormErrors['#{key}']"
            end

            def error_class
              get_from_error_config(:class) || 'error'
            end

            def error_tag
              get_from_error_config(:tag) || :div
              # error_config.is_a?(Hash) && error_config.dig(:tag) || :div
            end

            def input_error_class
              get_from_error_config(:input, :class) || 'error'
              # error_config.is_a?(Hash) && error_config.dig(:input, :class) || 'error'
            end

            def wrapper_tag
              get_from_error_config(:wrapper, :tag) || :div
              # error_config.is_a?(Hash) && error_config.dig(:wrapper, :tag) || :div
            end

            def wrapper_error_class
              get_from_error_config(:wrapper, :class) || 'errors'
              # error_config.is_a?(Hash) && error_config.dig(:wrapper, :class) || 'errors'
            end

            def get_from_error_config(*keys)
              comp_error_config = error_config.dig(*keys) if error_config.is_a?(Hash)
              form_error_config = form_context.ctx.errors.dig(*keys) if form_context.ctx.errors.is_a?(Hash)
              comp_error_config || form_error_config
            end

            def render_errors
              if display_errors?
                Matestack::Ui::Component.new(wrapper_tag, class: wrapper_error_class, 'v-if': error_key) do
                  Matestack::Ui::Component.new(error_tag, class: error_class, 'v-for': "error in #{error_key}") do
                    plain vue.error
                  end
                end
              end
            end

          end
        end
      end
    end
  end
end
