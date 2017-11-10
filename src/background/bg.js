'use strict';

const { ipcRenderer } = require('electron')
const Promise = require('bluebird')
const crypto = require('crypto')
const fs = Promise.promisifyAll(require('fs'))
const path = require('path')

// Send log and error messagse to main thread to show on the console
function log(value) {
    ipcRenderer.send('log', process.pid + ': ' + value)
}
function error(value) {
    ipcRenderer.send('error', process.pid + ': ' + value)
}

// let the main thread know this thread is ready to process something
function ready() {
    ipcRenderer.send('ready')
}

// see https://stackoverflow.com/questions/41206509/nodejs-hash-a-file-stream-using-promises
function createHash(file) {
    return new Promise((resolve, reject) => {
        let hash = crypto.createHash('md5')
        let stream = fs.createReadStream(file)
        stream.on('data', d => hash.update(d))
        stream.on('end', () => {
            resolve(hash.digest('hex'))
        })
        stream.on('error', reject)
    })
}

ipcRenderer.on('hash-file', (event, path) => {
    createHash(path).then(hash => {
        ipcRenderer.send('add-hash', {
            path: path,
            hash: hash
        })
    }).catch(err => {
        error(err)
    }).finally(() => {
        ready()
    })
})

ipcRenderer.on('delete-file', (event, path) => {
    fs.unlinkAsync(path).then(() => {
        ipcRenderer.send('file-deleted', path)
    }).catch(err => {
        error(err)
    }).finally(() => {
        ready()
    })
})

ipcRenderer.on('check-path', (event, path) => {
    fs.statAsync(path).then((stats) => {
        if (stats.isFile() && stats.size > 0) {
            ipcRenderer.send('add-file', {
                path: path,
                size: stats.size
            })
        } else if (stats.isDirectory()) {
            ipcRenderer.send('check-folder', path)
        }
    }).catch((err) => {
        error(err)
    }).finally(() => {
        ready()
    })
})

ipcRenderer.on('check-folder', (event, dir) => {
    fs.readdirAsync(dir).then((names) => {
        names.forEach(name => {
            ipcRenderer.send('check-path', path.join(dir, name))
        })
    }).catch((err) => {
        error(err)
    }).finally(() => {
        ready()
    })
})

ready()