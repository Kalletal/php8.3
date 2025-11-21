module.exports = {
	"parser": "vue-eslint-parser",
	"extends": ["eslint:recommended", "plugin:vue/vue3-recommended"],
	"env": {
		"browser": true,
		"es2021": true
	},
	"globals": {
		"SYNO": "readonly",
		"_S": "readonly"
	},
	"rules": {
		"vue/multi-word-component-names": "off",
		"vue/max-attributes-per-line": "off",
		"vue/singleline-html-element-content-newline": "off",
		"vue/multiline-html-element-content-newline": "off",
		"vue/attributes-order": "off"
	}
};
