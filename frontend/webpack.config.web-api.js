const path = require('path');
const webpack = require('webpack');

module.exports = {
  mode: 'development',
  entry: './main-web-api/demo.js',
  devServer: {
    hot: true,
    contentBase: './main-web-api',
    port: 8081,
    host: "0.0.0.0",
    historyApiFallback: true,
    proxy: {
      // Docker for Mac  only
      '/api': 'http://host.docker.internal:8080'
    }
  },
  output: {
    filename: 'demo.js',
    path: path.resolve(__dirname, 'main-web-api'),
    publicPath: '/'
  },
  devtool: 'eval',
  resolve: {
    alias: {
      'chart.js': 'chart.js/dist/Chart.js'
    }
  },
  plugins: [
    new webpack.HotModuleReplacementPlugin()
  ],
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
            presets: ['@babel/preset-env', '@babel/preset-react'],
            plugins: [
              'react-hot-loader/babel',
            ]
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
              require('autoprefixer')
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
            modules: true,
            localIdentName: '[local]--[hash:base64:5]'
          }
        }, {
          loader: 'postcss-loader',
          options: {
            plugins: () => [
              require('autoprefixer')
            ]
          }
        }]
      }
    ]
  }
};
