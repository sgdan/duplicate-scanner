'use strict';

const { ipcMain, BrowserWindow, app } = require('electron')
const cpus = require('os').cpus().length

// stack of available background threads
let available = []

// queue of tasks to be done
let tasks = []

let renderer

// hand the tasks out to waiting threads
function doIt() {
  while (available.length > 0 && tasks.length > 0) {
    let task = tasks.shift()
    let thread = available.shift()
    thread.send(task[0], task[1])
  }
}

app.on('ready', function () {
  // Create the "renderer" window which contains the visible UI
  renderer = new BrowserWindow({ "width": 900, "height": 768 })
  renderer.loadURL(`file://${__dirname}/src/renderer/index.html`)
  renderer.webContents.openDevTools()
  renderer.on('closed', function () {
    app.quit() // exit so background windows won't keep app running
  })

  // create a background thread for each cpu
  for (let i = 0; i < cpus; i++) {
    let bg = new BrowserWindow({ "show": false })
    bg.loadURL(`file://${__dirname}/src/background/bg.html`)
    //bg.webContents.openDevTools()
  }

  // check if the path is a file or folder
  ipcMain.on('check-path', (event, arg) => {
    tasks.push(['check-path', arg])
    doIt()
  })

  // search for non-empty files in the given folder
  ipcMain.on('check-folder', (event, arg) => {
    tasks.push(['check-folder', arg])
    renderer.webContents.send('add-dir', arg)
    doIt()
  })

  // calculate hash in background thread
  ipcMain.on('hash-file', (event, arg) => {
    tasks.push(['hash-file', arg])
    doIt()
  })

  ipcMain.on('delete-file', (event, arg) => {
    tasks.push(['delete-file', arg])
    doIt()
  })

  // messages from the background thread for the UI
  ipcMain.on('add-file', (event, arg) => {
    renderer.webContents.send('add-file', arg)
  })
  ipcMain.on('add-hash', (event, arg) => {
    renderer.webContents.send('add-hash', arg)
  })
  ipcMain.on('file-deleted', (event, arg) => {
    renderer.webContents.send('file-deleted', arg)
  })

  // bg thread ready for next task
  ipcMain.on('ready', (event, arg) => {
    available.push(event.sender)
    doIt()
  })

  // log message from bg thread
  ipcMain.on('log', (event, arg) => {
    console.log(arg)
  })

  // error messages from bg or UI
  ipcMain.on('error', (event, arg) => {
    console.error('error: ' + arg)
  })
})