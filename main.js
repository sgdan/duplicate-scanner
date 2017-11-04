const { ipcMain, BrowserWindow, app } = require('electron')
const cpus = 1 //require('os').cpus().length

// stack of available background threads
var available = []

// queue of tasks to be done
var tasks = []

let renderer

// hand the tasks out to waiting threads
function doIt() {
  while (available.length > 0 && tasks.length > 0) {
    var task = tasks.shift()
    available.shift().send(task[0], task[1])
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
  for (var i = 0; i < cpus; i++) {
    new BrowserWindow({ "show": false })
      .loadURL(`file://${__dirname}/src/background/bg.html`)
  }

  // search for non-empty files in the given folder
  ipcMain.on('open-folder', (event, arg) => {
    tasks.push(['open-folder', arg])
    doIt()
  })

  // calculate hash in background thread
  ipcMain.on('hash-file', (event, arg) => {
    tasks.push(['hash-file', arg])
    doIt()
  })

  // messages from the background thread tor the UI
  ipcMain.on('add-file', (event, arg) => {
    renderer.webContents.send('add-file', arg)
  })
  ipcMain.on('add-hash', (event, arg) => {
    renderer.webContents.send('add-hash', arg)
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
})