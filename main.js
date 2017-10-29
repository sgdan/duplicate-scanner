// see https://tutorialzine.com/2015/12/creating-your-first-desktop-app-with-html-js-and-electron

const electron = require('electron')
const app = electron.app
const BrowserWindow = electron.BrowserWindow

let mainWindow

app.on('window-all-closed', function() {
  if (process.platform != 'darwin') app.quit();  
})

app.on('ready', function() {
  mainWindow = new BrowserWindow({
    width: 1200, 
    height: 768
  })

  mainWindow.loadURL(`file://${ __dirname }/src/static/index.html`)
  mainWindow.webContents.openDevTools()
  mainWindow.on('closed', function () {
    mainWindow = null
  })
})
