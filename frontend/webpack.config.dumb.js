const path = require('path');
const webpack = require('webpack');

module.exports = {
  mode: 'development',
  entry: './main-dumb/demo.js',
  devServer: {
    hot: true,
    contentBase: './main-dumb',
    port: 8081,
    host: "0.0.0.0",
    historyApiFallback: true
  },
  output: {
    filename: 'demo.js',
    path: path.resolve(__dirname, 'main-dumb'),
    publicPath: '/'
  },
  devtool: 'eval',
  plugins: [
    new webpack.HotModuleReplacementPlugin()
  ],
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
          path.join(__dirname, 'main-dumb')
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
