const path = require('path');
//const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const TsconfigPathsPlugin = require('tsconfig-paths-webpack-plugin');
const TerserPlugin = require('terser-webpack-plugin');

var publicPath = 'http://localhost:4001/';

var babelLoader = {
  loader: 'babel-loader',
  options: {
    cacheDirectory: true,
    presets: [
      "@babel/preset-react",
      [
        "@babel/preset-env",
        {
          "modules": false
        }
      ]
    ]
  }
};

module.exports = (env, options) => ({
  mode: "development",
  optimization: {
    minimizer: [
      new TerserPlugin({
        cache: false,
        parallel: true,
        sourceMap: true,
        terserOptions: {
          keep_classnames: false,
          keep_fnames: false,
        }
      }),
      //      new UglifyJsPlugin({ cache: true, parallel: true, sourceMap: false }),
      new OptimizeCSSAssetsPlugin({})
    ]
  },
  devtool: 'eval-sourcemaps',
  entry: {
    './src/index.tsx': ['./src/index.tsx']
  },
  output: {
    publicPath: publicPath,
    filename: 'app.js',
    path: path.resolve(__dirname, '../priv/static/js')
  },
  watch: true,
  watchOptions: {
    poll: 2000,
    aggregateTimeout: 500,
    ignored: /node_modules/
  },
  module: {
    rules: [{
      test: /\.ts(x?)$/,
      exclude: /node_modules/,
      use: [
        babelLoader,
        {
          loader: 'ts-loader'
        }
      ]
    }, {
      test: /\.js$/,
      exclude: /node_modules/,
      use: [
        babelLoader
      ]
    }, {
      test: /\.css$/,
      //      use: [MiniCssExtractPlugin.loader, 'css-loader']
      use: ['style-loader', 'css-loader']
    },
    {
      test: /\.(ico|jpg|jpeg|png|gif|eot|otf|webp|svg|ttf|woff|woff2)(\?.*)?$/,
      loader: 'file-loader',
      query: {
        name: '[name].[hash:8].[ext]',
        outputPath: '../images',
        publicPath: "/images"
      }
    }]
  },
  resolve: {
    plugins: [new TsconfigPathsPlugin({ configFile: "./tsconfig.json" })],
    extensions: ['.ts', '.tsx', '.js']
  },
  plugins: [
    new TerserPlugin(),
    //   new MiniCssExtractPlugin({ filename: '../css/app.css' }),
    new CopyWebpackPlugin([{ from: 'static/', to: '../' }]),
    // new DefinePlugin({
    //   'process.env.NODE_ENV': JSON.stringify("production"),
    // })
  ]
});
