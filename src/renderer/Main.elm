module Main exposing (..)

import Html exposing (li, text, ul, button, program, div, Html, Attribute, fieldset, br)
import Html.Events exposing (on, onClick)
import Html.Attributes exposing (..)
import Ports exposing (..)
import Dict exposing (Dict)
import Set exposing (Set)

-- MODEL

type alias File = {
    path: String,           -- full path of file
    size: Int,              -- size in bytes
    hash: Maybe String      -- not always calculated
    }

type alias PathSet = Set String
type alias PathsBySize = Dict Int PathSet
type alias PathsByHash = Dict String PathSet

type alias Model = {
    dirs: PathSet,              -- names of the root folders we've scanned
    bySize: PathsBySize,        -- map files by size so we know what to hash
    hashing: PathSet,           -- waiting for md5sum to be returned by system
    byHash: PathsByHash         -- map by hash
    }

-- UPDATE
type Msg = OpenFolder
    | Clear
    | DirAdded String
    | FileAdded FileInfo
    | HashAdded FileHash

main: Program Never Model Msg
main = program {
    init = init,
    update = update,
    view = view,
    subscriptions = subscriptions}

init: (Model, Cmd Msg)
init = (emptyModel, Cmd.none)

emptyModel: Model
emptyModel = {
    dirs = Set.empty,
    bySize = Dict.empty,
    hashing = Set.empty,
    byHash = Dict.empty
    }

-- Add path to existing set, or create new set if no existing
addPath: String -> Maybe PathSet -> Maybe PathSet
addPath new existing = Just <| case existing of
    Just existing -> Set.insert new existing
    Nothing -> Set.singleton new

-- Update the size map with the give file info
updateBySize: FileInfo -> Model -> Model
updateBySize info model = {
    model | bySize = Dict.update info.size (addPath info.path) model.bySize    
    }

updateByHash: FileHash -> Model -> Model
updateByHash data model = {
    model | byHash = Dict.update data.hash (addPath data.path) model.byHash,
        hashing = Set.remove data.path model.hashing
    }

-- Create command to hash files that require it and ensure the
-- paths we're requesting hash for are added to the "hashing" set
requestHash: PathSet -> Model -> (Model, Cmd Msg)
requestHash paths model =
    if Set.isEmpty paths then (model, Cmd.none)
    else { model | hashing = Set.union model.hashing paths }
        ! (Set.toList paths |> List.map hashFile)

-- Figure out which files we need to request hash sums for
-- this means possible duplicates minus already hashed, minus hashing
findToHash: Model -> PathSet
findToHash model =
    Set.diff (possibleDuplicates model)
        <| Set.union (hashed model) model.hashing

-- Return set of paths whose size matches another path
possibleDuplicates: Model -> PathSet
possibleDuplicates model = Dict.foldl (\k v acc ->
        if Set.size v > 1 then Set.union acc v else acc
    ) Set.empty model.bySize

-- Return set of paths already hashed
hashed: Model -> PathSet
hashed model = Dict.foldl (\k v acc ->
        Set.union acc v
    ) Set.empty model.byHash

-- To keep only the root paths in the list
isChild a b = String.startsWith a b && not (a == b)
hasParentIn path list = List.any (\v -> isChild v path) list
parentsFrom paths = List.filter (\v -> not (hasParentIn v paths)) paths

-- Add a directory and remove any child folders
addFolder: String -> Model -> Model
addFolder dir model = {
    model | dirs = parentsFrom (dir :: Set.toList model.dirs) |> Set.fromList }
    {--
    Set.filter (\i -> True) {--isChild i model.dirs)--}
        (Set.insert dir model.dirs)
    }--}

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        -- MESSAGES FROM UI TO SYSTEM:
        OpenFolder -> (model, openFolder ()) -- ask system to open a folder and scan contents
        Clear -> (emptyModel, Cmd.none) -- Clear open folder list and existing results

        -- MESSAGES FROM SYSTEM TO UI:

        -- Add the opened folder to the list
        DirAdded value -> (addFolder value model, Cmd.none)

        -- Add the file name and size data to the model
        FileAdded value -> --requestHash (findToHash model) 
            (updateBySize value model, Cmd.none)

        HashAdded value -> (updateByHash value model, Cmd.none)

-- VIEW
view : Model -> Html Msg
view model = div [][
    -- List of open folders, blank if nothing selected
    Set.toList model.dirs
        |> folderList,

    -- Open/Clear buttons
    fieldset [defaultStyle][
        button [ buttonStyle, onClick OpenFolder ][ text "Open Folder" ],
        button [ onClick Clear ][ text "Clear" ]
    ],

    -- Total number of non-empty files in the model
    div [][
        text ("Number of files checked: " ++ (numFilesChecked model.bySize))
    ],

    -- List files being hashed
    div [][
        text ("Hashing: " ++ (toString (Set.size model.hashing)))
    ],

    -- List files being hashed
    div [][
        text ("byHash: " ++ (toString (Dict.size model.byHash)))
    ]

    -- Results of scan here
    --br[][],
    --sizesList (sameSize model.bySize)
    ]

{--
    Return only entries where there's more than one file. We only want to
    compute hash values for files that are the same size.
--}
sameSize: Dict Int PathSet -> Dict Int PathSet
sameSize entries = Dict.filter (\k v -> (Set.size v) > 1) entries

-- Count the number of non-empty files checked so far
numFilesChecked: Dict Int PathSet -> String
numFilesChecked bySize =
    Dict.foldl (\k v acc -> acc + (Set.size v)) 0 bySize
    |> toString

-- Turn set of same-size files into a display line
sizeListEntry: Int PathSet -> Html Msg
sizeListEntry size =
    "size: " ++ (toString size) ++ ": " --++ (toString files)
    |> text

sizesList: Dict Int PathSet -> Html Msg
sizesList entries = 
    if Dict.isEmpty entries then text ""
    else div [][
        text "Potential duplicates by file size:",
        ul [] (Dict.foldl (
            \k v acc -> (li [] [text (
                -- here is the line for this group of same-size files
                "size: " ++ (toString k) ++ " bytes, " ++ (toString (Set.size v)) ++ " files"
            )]) :: acc
        ) [] entries) 
    ]

folderList: List String -> Html Msg
folderList entries = case entries of
    [] -> text ""
    _ -> div [][
        text "Folders opened:",
        List.map (\x -> li [] [text x]) entries |> ul []
    ]

defaultStyle: Attribute msg
defaultStyle = style [
    ("width", "100%"),
    ("height", "40px"),
    ("padding", "10px"),
    ("font-size", "1em"),
    ("border", "0")]

buttonStyle: Attribute msg
buttonStyle = style [
    ("margin", "10px")]

subscriptions : Model -> Sub Msg
subscriptions model = Sub.batch [
    addDir DirAdded,
    addFile FileAdded,
    addHash HashAdded]
