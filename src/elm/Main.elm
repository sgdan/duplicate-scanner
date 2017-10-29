module Main exposing (..)

import Html exposing (li, text, ul, button, program, div, Html, Attribute, fieldset, br)
import Html.Events exposing (on, onClick)
import Html.Attributes exposing (..)
import Ports exposing (..)
import Dict exposing (Dict)
import Set exposing (Set)

-- MODEL
type alias FileSet = Set String -- just a set of file names

type alias Model = {
    dirs: Set String,
    -- we want to know which files are the same size so we can check them
    sizes: Dict Int FileSet
}

-- UPDATE
type Msg = OpenFolder
    | Clear
    | DirAdded String
    | FileAdded FileInfo

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
    sizes = Dict.empty}

-- Add file to the existing set, or create a new set if there isn't any existing
addFileSize: String -> Maybe FileSet -> Maybe FileSet
addFileSize new existing = Just <| case existing of
    Just existing -> Set.insert new existing
    Nothing -> Set.fromList [new]
    
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        -- MESSAGES FROM UI TO SYSTEM:
        OpenFolder -> (model, openFolder ()) -- ask system to open a folder and scan contents
        Clear -> (emptyModel, Cmd.none) -- Clear open folder list and existing results

        -- MESSAGES FROM SYSTEM TO UI:

        -- Add the opened folder to the list
        DirAdded value -> ({
            dirs = Set.insert value model.dirs,
            sizes = model.sizes
        }, Cmd.none)

        -- Add the file name and size data to the model
        FileAdded value -> ({
            dirs = model.dirs,
            sizes = Dict.update value.size (addFileSize value.name) model.sizes
        }, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model = Sub.batch [
    addDir DirAdded,
    addFile FileAdded]

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
        text ("Number of files checked: " ++ (numFilesChecked model.sizes))
    ],

    -- Results of scan here
    br[][],
    sizesList (sameSize model.sizes)
    ]

{--
    Return only entries where there's more than one file. We only want to
    compute hash values for files that are the same size.
--}
sameSize: Dict Int FileSet -> Dict Int FileSet
sameSize entries = Dict.filter (\k v -> (Set.size v) > 1) entries

-- Count the number of non-empty files checked so far
numFilesChecked: Dict Int FileSet -> String
numFilesChecked bySize =
    Dict.foldl (\k v acc -> acc + (Set.size v)) 0 bySize
    |> toString

-- Turn set of same-size files into a display line
sizeListEntry: Int FileSet -> Html Msg
sizeListEntry size =
    "size: " ++ (toString size) ++ ": " --++ (toString files)
    |> text

sizesList: Dict Int FileSet -> Html Msg
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