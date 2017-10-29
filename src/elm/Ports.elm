port module Ports exposing (..)

type alias FileInfo = {
    path : String,
    size : Int
}

type alias FileHash = {
    path : String,
    hash : String
}

-- messages from UI to System
port openFolder: () -> Cmd msg
port hashFiles: List String -> Cmd msg
port deleteFile: String -> Cmd msg

-- messages from System to UI
port addDir: (String -> msg) -> Sub msg
port addFile: (FileInfo -> msg) -> Sub msg
port addHash: (FileHash -> msg) -> Sub msg
port fileDeleted: (String -> msg) -> Sub msg
