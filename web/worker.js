'use strict';
var DirectoryChooser = javafx.stage.DirectoryChooser
var Platform = javafx.application.Platform
var Runnable = java.lang.Runnable
var File = java.io.File
var System = java.lang.System

load("web/hash.js")
var currentDir = new File(".")

var Chooser = Java.extend(Runnable, {
    run: function () {
        var chooser = new DirectoryChooser()
        chooser.title = "Choose a folder to scan"
        chooser.initialDirectory = currentDir
        var chosen = chooser.showDialog(null)
        if (chosen != null) {
            currentDir = chosen
            var path = chosen.toURI().toURL().toString().replaceAll("^file:/|/$","")
            ui.send("addDir", path, "2val")
            checkFolder(chosen)
        } 
    }
})

function openFolder() {
    Platform.runLater(new Chooser()) // JavaFX thread
}

function exit() {
    System.exit(0)
}

function checkFolder(dir) {
    for each (var file in dir.listFiles()) {
        if (file.isDirectory()) checkFolder(file)
        else {
            var size = file.length()
            var path = file.toURI().toURL().toString().replace("file:/", "")
            path = path.replaceAll("%20", " ")
            if (size > 0) ui.send("addFile", path, size)
        }
    }
}

function hashFile(path) {
    ui.send("addHash", path, md5sum(path))
}

function deleteFile(path) {
    var deleted = new File(path).delete()
    ui.send("fileDeleted", path)
}

this
