module Update exposing (update)

import Model exposing (..)
import Ports exposing (..)
import Set exposing (Set)
import Dict exposing (Dict)
import String exposing (toInt)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OpenFolder ->
            ( model, openFolder () )

        Close ->
            ( model, close () )

        DeleteFile path ->
            ( model, deleteFile path )

        -- ask system to open a folder and scan contents
        Clear ->
            ( emptyModel model.isWindows, Cmd.none )

        -- Clear open folder list and existing results
        SelectSize sizeInBytes ->
            processSizeSelection sizeInBytes model

        -- clear size selection to go back to folder page
        Back ->
            ( { model | selected = Nothing }, Cmd.none )

        -- Add the opened folder to the list
        DirAdded value ->
            ( addFolder value model, Cmd.none )

        FileDeleted value ->
            ( markDeleted value model, Cmd.none )

        -- Add the file name and size data to the model
        FileAdded value ->
            ( updateBySize value model, Cmd.none )

        HashAdded value ->
            ( updateByHash value model, Cmd.none )


processSizeSelection : Int -> Model -> ( Model, Cmd Msg )
processSizeSelection sizeInBytes model =
    let
        toHash =
            filesToHash sizeInBytes model
    in
        ( { model
            | selected = Just sizeInBytes
            , hashing = toHash
          }
        , toHash
            |> Set.toList
            |> List.map (\v -> hashFile v)
            |> Cmd.batch
        )


markDeleted : String -> Model -> Model
markDeleted path model =
    { model | deleted = Set.insert path model.deleted }



-- Decide which files need to be hashed based on the size selected


filesToHash : Int -> Model -> StringSet
filesToHash size model =
    Set.diff
        (Dict.get size model.sizeToPaths
            |> Maybe.withDefault Set.empty
        )
        (hashed
            model
        )



-- Add path to existing set, or create new set if no existing


addString : String -> Maybe StringSet -> Maybe StringSet
addString new existing =
    Just <|
        case existing of
            Just existing ->
                Set.insert new existing

            Nothing ->
                Set.singleton new



-- Update the size map with the give file info


updateBySize : FileInfo -> Model -> Model
updateBySize info model =
    { model
        | sizeToPaths = Dict.update info.size (addString info.path) model.sizeToPaths
        , pathToSize = Dict.insert info.path info.size model.pathToSize
    }


updateByHash : HashResult -> Model -> Model
updateByHash data model =
    { model
        | hashToPaths = Dict.update data.hash (addString data.path) model.hashToPaths
        , hashing = Set.remove data.path model.hashing
        , sizeToHashes = Dict.update (sizeOf data.path model) (addString data.hash) model.sizeToHashes
    }


sizeOf : String -> Model -> Int
sizeOf path model =
    Dict.get path model.pathToSize |> Maybe.withDefault 0



-- Create command to hash files that require it and ensure the
-- paths we're requesting hash for are added to the "hashing" set


requestHash : StringSet -> Model -> ( Model, Cmd Msg )
requestHash paths model =
    if Set.isEmpty paths then
        ( model, Cmd.none )
    else
        { model | hashing = Set.union model.hashing paths }
            ! (Set.toList paths |> List.map hashFile)



-- Figure out which files we need to request hash sums for
-- this means possible duplicates minus already hashed, minus hashing


findToHash : Model -> StringSet
findToHash model =
    Set.diff (possibleDuplicates model) <|
        Set.union (hashed model) model.hashing


possibleDuplicates : Model -> StringSet
possibleDuplicates model =
    Dict.foldl
        (\k v acc ->
            if Set.size v > 1 then
                Set.union acc v
            else
                acc
        )
        Set.empty
        model.sizeToPaths


hashed : Model -> StringSet
hashed model =
    Dict.foldl
        (\k v acc ->
            Set.union acc v
        )
        Set.empty
        model.hashToPaths


isChild : String -> String -> Bool
isChild a b =
    String.startsWith a b && not (a == b)


hasParentIn : String -> List String -> Bool
hasParentIn path list =
    List.any (\v -> isChild v path) list


parentsFrom : List String -> List String
parentsFrom paths =
    List.filter (\v -> not (hasParentIn v paths)) paths


addFolder : String -> Model -> Model
addFolder dir model =
    { model
        | dirs = parentsFrom (dir :: Set.toList model.dirs) |> Set.fromList
        , selected = Nothing
    }
