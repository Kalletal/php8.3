const path = require('path');
const webpack = require('webpack');
const VueLoaderPlugin = require('vue-loader/lib/plugin');
const ESLintPlugin = require('eslint-webpack-plugin');

function resolve (dir) {
	return path.join(__dirname, dir)
}

module.exports = async (env, argv) => {
	const isDevelopment = argv.mode === 'development';
	return {
		mode: isDevelopment ? 'development' : 'production',
		devtool: isDevelopment ? 'inline-source-map' : false,
		module: {
			rules: [
				{
					test: /\.vue$/,
					loader: 'vue-loader'
				},
				{
					exclude: /node_modules/,
					test: /\.js$/,
					use: {
						loader: 'babel-loader',
						options: {
							rootMode: 'upward'
						}
					}
				},
			]
		},
		resolve: {
			extensions: ['.js', '.vue', '.json'],
		},
		entry: {
			// uninstall entry
			remove_entry: './src/remove-entry.js',
			remove_notice_entry: './src/remove-notice-entry.js',
			// install entry
			install_entry: './src/install-entry.js',
		},
		output: {
			library: {
				name: 'SYNO.SDS.PkgManApp.Custom.JsonpLoader.load',
				type: 'jsonp',
			},
			path: resolve('dist'),
			filename: '[name].bundle.js'
		},
		plugins: [
			new VueLoaderPlugin(),
			new ESLintPlugin({ extensions: ['js', 'ts', 'vue'] }),
		],
		externalsType: 'window',
		externals: {
			'vue': 'Vue',
		},
		watchOptions: {
			poll: true,
		},
	};
}
