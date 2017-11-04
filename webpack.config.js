module.exports = {
    target: 'electron-main',
    entry: './src/renderer/index.js',
    output: {
        path: __dirname + '/dist',
        publicPath: '/assets/',
        filename: 'bundle.js'
    },
    module: {
        loaders: [
            {
                test:    /\.elm$/,
                exclude: [/elm-stuff/, /node_modules/],
                loader:  'elm-webpack-loader?verbose=true&warn=true',
            }
        ]
    },
    resolve: {
        extensions: ['.js', '.elm']
    },
    devServer: { inline: true }
}