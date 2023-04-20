const path = require('path');
const webpack = require('webpack');

module.exports = {
  mode: 'production',
  entry: './src/main.js',
  output: {
    filename: 'app.js',
    path: path.resolve(__dirname, '../assets')
  },
  devtool: false,
  resolve: {
    alias: {
      'chart.js': 'chart.js/dist/Chart.js'
    }
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        include: [
          path.join(__dirname, 'src'),
          path.join(__dirname, 'main-web-api')
        ],
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['@babel/preset-env', '@babel/preset-react']
          }
        }
      }, {
        test: /\.(scss)$/,
        use: [{
          loader: 'style-loader'
        }, {
          loader: 'css-loader'
        }, {
          loader: 'postcss-loader',
          options: {
            plugins: () => [
              require('autoprefixer'),
              require('cssnano')
            ]
          }
        }, {
          loader: 'sass-loader'
        }]
      }, {
        test: /\.module\.css$/,
        include: path.resolve(__dirname, 'src', 'dumb'),
        use: [{
          loader: 'style-loader'
        }, {
          loader: 'css-loader',
          options: {
            modules: true
          }
        }, {
          loader: 'postcss-loader',
          options: {
            plugins: () => [
              require('autoprefixer'),
              require('cssnano')
            ]
          }
        }]
      }
    ]
  }
};
