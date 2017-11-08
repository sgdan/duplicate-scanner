module Model exposing (..)

import Set exposing (Set)
import Dict exposing (Dict)


type alias PathSet =
    Set String


type alias HashSet =
    Set String


type alias PathsBySize =
    Dict Int PathSet


type alias PathsByHash =
    Dict String PathSet


type alias HashBySize =
    Dict Int HashSet


type alias Model =
    { dirs : PathSet -- names of the root folders we've scanned
    , bySize : PathsBySize -- map files by size so we know what to hash
    , hashBySize : HashBySize -- map size to set of hash values
    , hashing : PathSet -- waiting for md5sum to be returned by system
    , hashed : PathSet -- already hashed
    , byHash : PathsByHash -- map by hash
    , selected : Maybe Int -- current size selection
    }


type Msg
    = OpenFolder
    | Clear
    | DirAdded String
    | FileAdded FileInfo
    | HashAdded FileHash
    | SelectSize String


type alias FileInfo =
    { path : String
    , size : Int
    }


type alias FileHash =
    { path : String
    , hash : String
    }


emptyModel : Model
emptyModel =
    { dirs = Set.empty
    , bySize = Dict.empty
    , hashBySize = Dict.empty
    , hashing = Set.empty
    , hashed = Set.empty
    , byHash = Dict.empty
    , selected = Nothing
    }
