const { ipcMain, BrowserWindow, app } = require('electron')
const cpus = require('os').cpus().length

// stack of available background threads
var available = []

// queue of tasks to be done
var tasks = []

// hand the tasks out to waiting threads
function doIt() {
  while (available.length > 0 && tasks.length > 0) {
    var task = tasks.shift()
    available.shift().send(task[0], task[1])
  }
  renderer.webContents.send('status', available.length, tasks.length)
}

// Create a hidden background window
function createBgWindow() {
  result = new BrowserWindow({ "show": false })
  result.loadURL('http://localhost:8080/assets/bg.bundle.js')
  result.on('closed', () => {
    console.log('background window closed')
  });
  return result
}

let mainWindow

app.on('window-all-closed', function () {
  if (process.platform != 'darwin') app.quit();
})

app.on('ready', function () {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 768
  })
  mainWindow.loadURL(`file://${__dirname}/src/renderer/index.html`)
  mainWindow.webContents.openDevTools()
  mainWindow.on('closed', function () {
    app.quit() // exit so background windows won't keep app running
  })

  // create background thread for each cpu
  for (var i = 0; i < cpus; i++) createBgWindow()
})
