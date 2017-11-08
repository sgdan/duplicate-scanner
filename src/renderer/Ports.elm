port module Ports exposing (..)

import Model exposing (..)


-- messages from UI to System


port openFolder : () -> Cmd msg


port hashFile : String -> Cmd msg


port deleteFile : String -> Cmd msg



-- messages from System to UI


port addDir : (String -> msg) -> Sub msg


port addFile : (FileInfo -> msg) -> Sub msg


port addHash : (FileHash -> msg) -> Sub msg


port fileDeleted : (String -> msg) -> Sub msg
