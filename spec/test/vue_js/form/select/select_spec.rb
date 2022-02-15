require 'rails_vue_js_spec_helper'
require_relative "../../support/test_controller"
require_relative "../support/form_test_controller"
require_relative "../support/model_form_test_controller"
include VueJsSpecUtils

describe "Form Component", type: :feature, js: true do

  describe "Select" do

    before :all do
      Rails.application.routes.append do
        post '/select_success_form_test/:id', to: 'form_test#success_submit', as: 'select_success_form_test'
        post '/select_success_form_test_with_transition/:id', to: 'form_test#success_submit_with_transition', as: 'select_success_form_test_with_transition'
        post '/select_failure_form_test_with_transition/:id', to: 'form_test#failure_submit_with_transition', as: 'select_failure_form_test_with_transition'
        post '/select_success_form_test_with_redirect/:id', to: 'form_test#success_submit_with_redirect', as: 'select_success_form_test_with_redirect'
        post '/select_failure_form_test_with_redirect/:id', to: 'form_test#failure_submit_with_redirect', as: 'select_failure_form_test_with_redirect'
        post '/select_failure_form_test/:id', to: 'form_test#failure_submit', as: 'select_failure_form_test'
        post '/select_model_form_test', to: 'model_form_test#model_submit', as: 'select_model_form_test'
      end
      Rails.application.reload_routes!
    end

    after :all do
      Object.send(:remove_const, :TestModel)
      load "#{Rails.root}/app/models/test_model.rb"
    end

    before :each do
      allow_any_instance_of(FormTestController).to receive(:expect_params)
    end

    describe "DOM structure" do
      it "is properly rendered" do
        class ExamplePage < Matestack::Ui::Page
          def response
            matestack_form form_config do
              form_select key: :plain_input, options: [1, 2]
              form_select key: :input_with_id, options: [1, 2], id: "some-id"
              form_select key: :input_with_id_and_class, options: [1, 2], id: "some-other-id", class: "some-class"
              button "Submit me!"
            end
          end

          def form_config
            return {
              for: :my_object,
              method: :post,
              path: select_success_form_test_path(id: 42)
            }
          end
        end

        visit "/example"
        # sleep

        expect(page).to have_selector('form > matestack-component-template > div.matestack-ui-core-form-select > select#plain_input')
        expect(page).to have_selector('form > matestack-component-template > div.matestack-ui-core-form-select > select#plain_input > option[value="1"]' )
        expect(page).to have_selector('form > matestack-component-template > div.matestack-ui-core-form-select > select#plain_input > option[value="2"]' )

        expect(page).to have_selector('form > matestack-component-template > div.matestack-ui-core-form-select > select#some-id')
        expect(page).to have_selector('form > matestack-component-template > div.matestack-ui-core-form-select > select#some-id > option[value="1"]' )
        expect(page).to have_selector('form > matestack-component-template > div.matestack-ui-core-form-select > select#some-id > option[value="2"]' )

        expect(page).to have_selector('form > matestack-component-template > div.matestack-ui-core-form-select > select#some-other-id.some-class')
        expect(page).to have_selector('form > matestack-component-template > div.matestack-ui-core-form-select > select#some-other-id.some-class > option[value="1"]' )
        expect(page).to have_selector('form > matestack-component-template > div.matestack-ui-core-form-select > select#some-other-id.some-class > option[value="2"]' )
      end
    end

    describe "Dropdown" do

      it "takes an array of options or hash and submits selected item" do
        class ExamplePage < Matestack::Ui::Page

          def response
            matestack_form form_config do
              form_select id: "my-array-test-dropdown", key: :array_input, options: ["Array Option 1","Array Option 2"]
              form_select id: "my-hash-test-dropdown", key: :hash_input, options: { "Hash Option 1": 1, "Hash Option 2": 2 }
              button "Submit me!"
            end
          end

          def form_config
            {
              for: :my_object,
              method: :post,
              path: select_success_form_test_path(42)
            }
          end

        end

        visit "/example"

        select "Array Option 2", from: "my-array-test-dropdown"
        select "Hash Option 2", from: "my-hash-test-dropdown"
        expect_any_instance_of(FormTestController).to receive(:expect_params)
          .with(hash_including(my_object: { array_input: "Array Option 2", hash_input: 2 }))
        click_button "Submit me!"
      end

      it "can be initialized with value" do
        class ExamplePage < Matestack::Ui::Page
          def response
            matestack_form form_config do
              form_select id: "my-array-test-dropdown", key: :array_input, options: ["Array Option 1","Array Option 2"], init: "Array Option 1"
              form_select id: "my-hash-test-dropdown", key: :hash_input, options: { "Hash Option 1": 1, "Hash Option 2": 2 }, init: 1
              button "Submit me!"
            end
          end

          def form_config
            {
              for: :my_object,
              method: :post,
              path: select_success_form_test_path(42)
            }
          end
        end

        visit "/example"
        expect(page).to have_field("my-array-test-dropdown", with: "Array Option 1")
        expect(page).to have_field("my-hash-test-dropdown", with: 1)
        select "Array Option 2", from: "my-array-test-dropdown"
        select "Hash Option 2", from: "my-hash-test-dropdown"
        expect_any_instance_of(FormTestController).to receive(:expect_params)
          .with(hash_including(my_object: { array_input: "Array Option 2", hash_input: 2 }))
        click_button "Submit me!"
      end

      it "can be mapped to an Active Record Model Array Enum" do
        Object.send(:remove_const, :TestModel)

        class TestModel < ApplicationRecord
          enum status: [ :active, :archived ]
        end

        class ExamplePage < Matestack::Ui::Page
          def prepare
            @test_model = TestModel.new
            @test_model.status = "active"
          end

          def response
            matestack_form form_config do
              form_input id: "description", key: :description, type: :text
              # TODO: Provide better Enum Options API
              form_select id: "status", key: :status, options: TestModel.statuses, init: TestModel.statuses[@test_model.status]
              button "Submit me!"
            end
          end

          def form_config
            return {
              for: @test_model,
              method: :post,
              path: select_model_form_test_path
            }
          end
        end

        visit "/example"
        value = "#{DateTime.now}"
        expect(page).to have_field("status", with: 0)

        fill_in "description", with: value
        select "archived", from: "status"
        click_button "Submit me!"
        expect(page).to have_field("status", with: 0)
        expect(page).to have_field("description", with: "")
        expect(TestModel.last.description).to eq(value)
        expect(TestModel.last.status).to eq("archived")
      end

      it "can be mapped to an Active Record Model Hash Enum" do
        Object.send(:remove_const, :TestModel)

        class TestModel < ApplicationRecord
          enum status: { active: 0, archived: 1 }
        end

        class ExamplePage < Matestack::Ui::Page
          def prepare
            @test_model = TestModel.new
            @test_model.status = "active"
          end

          def response
            matestack_form form_config do
              form_input id: "description", key: :description, type: :text
              # TODO: Provide better Enum Options API
              form_select id: "status", key: :status, options: TestModel.statuses, init: TestModel.statuses[@test_model.status]
              button "Submit me!"
            end
          end

          def form_config
            return {
              for: @test_model,
              method: :post,
              path: select_model_form_test_path
            }
          end
        end

        visit "/example"
        value = "#{DateTime.now}"
        expect(page).to have_field("status", with: 0)

        fill_in "description", with: value
        select "archived", from: "status"
        click_button "Submit me!"
        expect(page).to have_field("status", with: 0)
        expect(page).to have_field("description", with: "")
        expect(TestModel.last.description).to eq(value)
        expect(TestModel.last.status).to eq("archived")
      end

      it "can be mapped to Active Record Model Errors" do
        Object.send(:remove_const, :TestModel)

        class TestModel < ApplicationRecord
          enum status: { active: 0, archived: 1 }
          validates :status, presence: true
        end

        class ExamplePage < Matestack::Ui::Page
          def prepare
            @test_model = TestModel.new
          end

          def response
            matestack_form form_config do
              # TODO: Provide better Enum Options API
              form_select id: "status", key: :status, options: TestModel.statuses, init: TestModel.statuses[@test_model.status]
              button "Submit me!"
            end
          end

          def form_config
            return {
              for: @test_model,
              method: :post,
              path: select_model_form_test_path
            }
          end
        end

        visit "/example"
        expect(page).to have_field("status", with: nil)

        click_button "Submit me!"
        expect(page).to have_xpath('//div[@class="errors"]/div[@class="error" and contains(.,"can\'t be blank")]')
      end

      it "can have a label"

      it "can have a placeholder"

      it "can have a class" do
        class ExamplePage < Matestack::Ui::Page
          def response
            matestack_form form_config do
              form_select id: "my-array-test-dropdown", key: :array_input, options: ["Array Option 1","Array Option 2"], class: "form-control"
              form_select id: "my-hash-test-dropdown", key: :hash_input, options: { "Hash Option 1": 1, "Hash Option 2": 2 }, class: "form-control"
              button "Submit me!"
            end
          end

          def form_config
            return {
              for: :my_object,
              method: :post,
              path: select_success_form_test_path(42),
            }
          end
        end

        visit "/example"
        expect(page).to have_css("#my-array-test-dropdown.form-control")
        expect(page).to have_css("#my-hash-test-dropdown.form-control")
      end
    end

  end

end
