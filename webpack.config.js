module.exports = {
    target: 'electron-main',
    entry: {
        'renderer': './src/renderer/index.js',
        'bg': './src/background/bg.js'
    },
    output: {
        path: __dirname + '/dist',
        publicPath: '/assets/',
        filename: '[name].bundle.js'
    },
    module: {
        loaders: [
            {
                test: /\.elm$/,
                exclude: [/elm-stuff/, /node_modules/],
                loader: 'elm-webpack-loader?verbose=true&warn=true',
            }
        ]
    },
    resolve: {
        extensions: ['.js', '.elm']
    },
    devServer: { inline: true }
}