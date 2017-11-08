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

        -- ask system to open a folder and scan contents
        Clear ->
            ( emptyModel, Cmd.none )

        -- Clear open folder list and existing results
        SelectSize value ->
            ( { model
                | selected = toSize value
                , hashing = filesToHash (toSize value) model
              }
            , filesToHash (toSize value) model
                |> Set.toList
                |> List.map (\v -> hashFile v)
                |> Cmd.batch
            )

        -- Add the opened folder to the list
        DirAdded value ->
            ( addFolder value model, Cmd.none )

        -- Add the file name and size data to the model
        FileAdded value ->
            --requestHash (findToHash model)
            ( updateBySize value model, Cmd.none )

        HashAdded value ->
            ( updateByHash value model, Cmd.none )


toSize : String -> Maybe Int
toSize str =
    toInt str |> Result.toMaybe



-- Decide which files need to be hashed based on the size selected


filesToHash : Maybe Int -> Model -> PathSet
filesToHash value model =
    case value of
        Nothing ->
            Set.empty

        Just size ->
            Set.diff
                (Dict.get size model.bySize
                    |> Maybe.withDefault Set.empty
                )
                model.hashed


addPath : String -> Maybe PathSet -> Maybe PathSet



-- Add path to existing set, or create new set if no existing


addPath new existing =
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
        | bySize = Dict.update info.size (addPath info.path) model.bySize
    }


updateByHash : FileHash -> Model -> Model
updateByHash data model =
    { model
        | byHash = Dict.update data.hash (addPath data.path) model.byHash
        , hashing = Set.remove data.path model.hashing
        , hashed = Set.insert data.path model.hashed
    }



-- Create command to hash files that require it and ensure the
-- paths we're requesting hash for are added to the "hashing" set


requestHash : PathSet -> Model -> ( Model, Cmd Msg )
requestHash paths model =
    if Set.isEmpty paths then
        ( model, Cmd.none )
    else
        { model | hashing = Set.union model.hashing paths }
            ! (Set.toList paths |> List.map hashFile)



-- Figure out which files we need to request hash sums for
-- this means possible duplicates minus already hashed, minus hashing


findToHash : Model -> PathSet
findToHash model =
    Set.diff (possibleDuplicates model) <|
        Set.union (hashed model) model.hashing


possibleDuplicates : Model -> PathSet
possibleDuplicates model =
    Dict.foldl
        (\k v acc ->
            if Set.size v > 1 then
                Set.union acc v
            else
                acc
        )
        Set.empty
        model.bySize


hashed : Model -> PathSet
hashed model =
    Dict.foldl
        (\k v acc ->
            Set.union acc v
        )
        Set.empty
        model.byHash


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
    }
