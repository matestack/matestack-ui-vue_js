import matestackEventHub from '../../event_hub'
import queryParamsHelper from '../../helpers/query_params_helper'
import componentMixin from '../mixin'
import componentHelpers from '../helpers'

const componentDef = {
  mixins: [componentMixin],
  template: componentHelpers.inlineTemplate,
  data: function(){
    return {
      ordering: {}
    }
  },
  methods: {
    toggleOrder: function(key){
      if (this.ordering[key] == undefined) {
        this.ordering[key] = "asc"
      } else if (this.ordering[key] == "asc") {
        this.ordering[key] = "desc"
      } else if (this.ordering[key] == "desc") {
        this.ordering[key] = undefined
      }
      var url;
      url = queryParamsHelper.updateQueryParams(this.props["id"] + "-order-" + key, this.ordering[key])
      url = queryParamsHelper.updateQueryParams(this.props["id"] + "-offset", 0, url)
      window.history.pushState({matestackApp: true, url: url}, null, url);
      matestackEventHub.$emit(this.props["id"] + "-update")
      this.$forceUpdate()
    },
    isDefaultOrdering: function(key){
      return this.ordering[key] == undefined;
    },
    isAscendingOrdering: function(key){
      return this.ordering[key] == "asc";
    },
    isDescendingOrdering: function(key){
      return this.ordering[key] == "desc";
    },
  },
  created: function(){
    var self = this;
    var queryParamsObject = queryParamsHelper.queryParamsToObject()
    Object.keys(queryParamsObject).forEach(function(key){
      if (key.startsWith(self.props["id"] + "-order-")){
        self.ordering[key.replace(self.props["id"] + "-order-", "")] = queryParamsObject[key]
      }
    })
  }
}

export default componentDef
