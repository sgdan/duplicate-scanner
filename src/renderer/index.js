'use strict';

const { ipcRenderer } = require('electron')
let Elm = require('./Main')
let container = document.getElementById('container')
let elmApp = Elm.Main.embed(container)
let dialog = require('electron').remote.dialog

// open the folder, send info of files within
elmApp.ports.openFolder.subscribe(() => {
    dialog.showOpenDialog(
        { properties: ['openDirectory'] },
        (dirs) => {
            if (dirs === undefined) return
            let dir = dirs[0]
            ipcRenderer.send('check-folder', dir)
        }
    )
})

elmApp.ports.hashFile.subscribe(file => {
    ipcRenderer.send('hash-file', file)
})
elmApp.ports.deleteFile.subscribe(file => {
    ipcRenderer.send('delete-file', file)
})

ipcRenderer.on('add-dir', (event, arg) => {
    elmApp.ports.addDir.send(arg)
})
ipcRenderer.on('add-file', (event, arg) => {
    elmApp.ports.addFile.send(arg)
})
ipcRenderer.on('add-hash', (event, arg) => {
    elmApp.ports.addHash.send(arg)
})
ipcRenderer.on('file-deleted', (event, arg) => {
    elmApp.ports.fileDeleted.send(arg)
})