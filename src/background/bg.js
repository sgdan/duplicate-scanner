const { ipcRenderer } = require('electron')
const crypto = require('crypto')
const fs = require('fs')
const path = require('path')

// Send log message to main thread to show on the console
function log(value) {
    ipcRenderer.send('log', process.pid + ': ' + value)
}

// let the main thread know this thread is ready to process something
function ready() {
    log('ready')
    ipcRenderer.send('ready')
}

ipcRenderer.on('hash-file', (event, arg) => {
    log('hashing file: ' + arg)
    var hash = crypto.createHash('md5')
    var stream = fs.createReadStream(arg)
    stream.on('data', (data) => {
        hash.update(data, 'utf8')
    })
    stream.on('end', () => {
        var result = hash.digest('hex')
        ipcRenderer.send('add-hash', {
            path: arg,
            hash: result
        })
        ready()
    })
})

ipcRenderer.on('delete-file', (event, arg) => {
    log('request to delete ' + arg)
    //port fileDeleted: (String -> msg) -> Sub msg
    ready()
})

/**
 * Recurse through the given folder and notify the UI of any non-empty
 * files contained within.
 * 
 * Note: Using synchronous operations here because this is a background
 * thread created for this purpose. Also we want to be able to notify the
 * main thread when we're finished which would not be possible with multiple
 * async recursive calls.
 */
ipcRenderer.on('open-folder', (event, arg) => {
    var dirs = [arg]
    while (dirs.length > 0) {
        var dir = dirs.shift()
        fs.readdirSync(dir).map((entry) => {
            return path.join(dir, entry)
        }).forEach((entry) => {
            var stats = fs.statSync(entry)
            if (stats.isDirectory()) {
                dirs.push(entry)
            } else if (stats.isFile()) {
                var size = stats.size
                if (size > 0) ipcRenderer.send('add-file', {
                    path: entry,
                    size: size
                })
            }
        })
    }
    ready()
})

ready()