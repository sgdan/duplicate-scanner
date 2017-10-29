# duplicate-scanner

Aim is to write a small desktop utility app which will scan some local
folders to see if there are any duplicate files. If duplicates are identified it will allow to choose which ones should be deleted.

Current status: Incomplete (just counts files of the same size)

Uses Elm for the UI code and runs on Electron. File system operations are written in JavaScript.

# How to run

- See following links which are very helpful setting up the environment:
  * https://github.com/johnomarkid/elm-electron-webpack
  * https://medium.com/@ezekeal/building-an-electron-app-with-elm-part-1-boilerplate-3416a730731f
- Assumes the following tools are installed: NodeJS, Elm, Electron, webpack-dev-server
- Install Elm packages:
```
elm package install elm-lang/html
```
- Elm Webpack loader must be installed:
```
npm install --save elm-webpack-loader
```
- Use electron to run and provide debug tools
```
electron main.js
```
# How to use

- Click the "Open Folder" button and browse to a local folder
- UI will show number of files checked and number of potential duplicates

# TODO features not implemented yet

- Compute md5sum hash values for files of the same size to see if they're duplicates
- Display duplicate file groups in the UI
- Provide delete option in the UI so duplicate files can be removed
- Package into executable format