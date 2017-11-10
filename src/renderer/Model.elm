module Model exposing (..)

import Set exposing (Set)
import Dict exposing (Dict)


type alias FileInfo =
    { path : String, size : Int }


type alias HashResult =
    { path : String, hash : String }


type alias StringSet =
    Set String


type alias Model =
    { dirs : StringSet -- names of the root folders we've scanned
    , sizeToPaths : Dict Int StringSet
    , pathToSize : Dict String Int
    , sizeToHashes : Dict Int StringSet
    , hashToPaths : Dict String StringSet
    , hashing : StringSet -- waiting for md5sum to be returned by system
    , selected : Maybe Int -- current size selection
    }


emptyModel : Model
emptyModel =
    { dirs = Set.empty
    , sizeToPaths = Dict.empty
    , pathToSize = Dict.empty
    , sizeToHashes = Dict.empty
    , hashToPaths = Dict.empty
    , hashing = Set.empty
    , selected = Nothing
    }


type Msg
    = OpenFolder
    | Clear
    | DirAdded String
    | FileAdded FileInfo
    | HashAdded HashResult
    | SelectSize String
