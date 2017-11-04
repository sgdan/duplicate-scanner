var Elm = require('./Main');
var container = document.getElementById('container');
var elmApp = Elm.Main.embed(container);
var dialog = require('electron').remote.dialog
var fs = require('fs')
var path = require('path')

// recurse through folder structure sending info of all non-empty files to elm app
function sendFilesFrom(dir) {
    fs.readdir(dir, (err, entries) => {
        if (err) throw err;
        entries.map((entry) => {
            return path.join(dir, entry)
        }).filter((entry) => {
            return fs.stat(entry, (err, stats) => {
                if (err) throw err;
                if (stats.isFile()) {
                    var size = stats.size
                    if (size > 0) elmApp.ports.addFile.send({
                        path: entry,
                        size: size
                    })
                    console.log("adding " + entry + " of size " + size)
                }
                else if (stats.isDirectory()) sendFilesFrom(entry)
            })
        })
    });
}

// open the folder, send info of files within
elmApp.ports.openFolder.subscribe(() => {
    console.log('openFolder called')
    dialog.showOpenDialog(
        { properties: ['openDirectory'] },
        (dirs) => {
            if (dirs === undefined) return;
            var dir = dirs[0]
            elmApp.ports.addDir.send(dir)
            sendFilesFrom(dir)
        }
    );
});
    
elmApp.ports.hashFiles.subscribe(files => {
    console.log('request to hash files: ' + files)
});
