'use strict';

//const os = require('os')
var node = document.getElementById('main')
const elmApp = Elm.Main.embed(node, {
    isWindows: true //os.platform() == 'win32'
})

function addDir(dir) {
    elmApp.ports.addDir.send(dir.toString())
}

function addFile(path, size) {
    elmApp.ports.addFile.send({
        path: path,
        size: size
    })
}

function addHash(path, hash) {
    elmApp.ports.addHash.send({
        path: path,
        hash: hash
    })
}

function fileDeleted(path) {
    elmApp.ports.fileDeleted.send(path)
}

// open the folder, send info of files within
elmApp.ports.openFolder.subscribe(() => {
    send("openFolder")
})

elmApp.ports.close.subscribe(() => {
    send("exit")
})

elmApp.ports.hashFile.subscribe(file => {
    send("hashFile", file)
})
elmApp.ports.deleteFile.subscribe(file => {
    send("deleteFile", file)
})
