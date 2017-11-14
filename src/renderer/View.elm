module View exposing (view)

import Model exposing (..)
import Html exposing (..)
import Html.Events exposing (on, onClick, onInput, targetValue)
import Html.Attributes exposing (..)
import Dict exposing (Dict)
import Set exposing (Set)
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (usLocale)
import Path.Generic as Path
import Array exposing (Array)


view : Model -> Html Msg
view model =
    case model.selected of
        Nothing ->
            folderPage model

        Just size ->
            filePage model


folderPage : Model -> Html Msg
folderPage model =
    div []
        [ div [ class "left-margin" ] []
        , div [ class "right-margin" ] []
        , div [ class "left-back" ]
            [ button [ onClick Close ] [ text "Close" ]
            ]
        , div [ class "right-buttons" ]
            [ button [ onClick OpenFolder ] [ text "Open" ]
            , button [ onClick Clear ] [ text "Clear" ]
            ]
        , div [ class "app-header" ]
            [ h1 [] [ text "Duplicates" ]
            ]
        , div [ class "folders" ] (folderList model)
        , div [ class "checked" ]
            [ span [ class "alignBottom" ] [ checkedMsg model ]
            ]
        , div [ class "content" ] (fileSets model)
        ]


sameSize : Model -> Dict Int StringSet
sameSize model =
    -- filter out groups of files that are the same size
    Dict.filter (\k v -> (Set.size v) > 1) model.sizeToPaths


sameSizeEntry : Int -> Int -> List (Html Msg)
sameSizeEntry sizeInBytes numFiles =
    let
        sizeDesc =
            formatSize sizeInBytes

        countDesc =
            (toString numFiles) ++ " files"
    in
        [ div [ class "fileAction" ]
            [ button [ onClick <| SelectSize sizeInBytes, class "selectButton" ] []
            ]
        , div [ class "fileIcon" ] [ img [ src "images/files-icon.png" ] [] ]
        , div [ class "fileName" ]
            [ span [ class "fileNameText" ] [ text sizeDesc ]
            ]
        , div [ class "filePath" ] [ text countDesc ]
        ]


appendEntry : Int -> StringSet -> List (Html Msg) -> List (Html Msg)
appendEntry size paths entries =
    let
        entry =
            sameSizeEntry size <| Set.size paths
    in
        entry ++ entries


fileSets : Model -> List (Html Msg)
fileSets model =
    sameSize model
        |> Dict.foldl appendEntry []


checkedMsg : Model -> Html msg
checkedMsg model =
    let
        count =
            numFilesChecked model.sizeToPaths
    in
        if count == "0" then
            text ""
        else
            text <| "Checked " ++ count ++ " files"


platform : Model -> Path.Platform
platform model =
    if model.isWindows then
        Path.Windows
    else
        Path.Posix


folder : Model -> String -> List (Html msg)
folder model path =
    let
        plat =
            platform model

        name =
            Path.takeFileName plat path

        dir =
            Path.takeDirectory plat path
    in
        [ div [ class "fileAction" ] []
        , div [ class "fileIcon" ] [ img [ src "images/open-folder-icon.png" ] [] ]
        , div [ class "fileName" ]
            [ span [ class "fileNameText" ] [ text name ]
            ]
        , div [ class "filePath" ] [ text dir ]
        ]


folderList : Model -> List (Html msg)
folderList model =
    model.dirs
        |> Set.foldl (\v acc -> acc ++ (folder model v)) []


filePage : Model -> Html Msg
filePage model =
    div []
        [ div [ class "left-margin" ] []
        , div [ class "right-margin" ] []
        , div [ class "left-back" ]
            [ button [ onClick Back, class "backButton" ] []
            , button [ onClick Close ] [ text "Close" ]
            ]
        , div [ class "right-buttons" ]
            [ br [] []
            , input [ type_ "checkbox", checked model.safeMode, onClick ToggleSafe ] []
            , text
                "Safe Mode"
            ]
        , div [ class "app-header" ]
            [ h1 [] [ text "Duplicates" ]
            ]
        , div [ class "files" ]
            (displaySets model)
        ]


type alias DisplaySet =
    { model : Model
    , paths : StringSet
    }


displaySetAction : Model -> String -> Bool -> Html Msg
displaySetAction model path locked =
    if Set.member path model.deleted then
        div [] [ img [ src "images/deleted-file.png" ] [] ]
    else if Set.member path model.hashing then
        div [] [ br [] [], text "HASHING" ]
    else if model.safeMode && locked then
        div [] [ img [ src "images/locked.png" ] [] ]
    else
        button [ onClick (DeleteFile path), class "deleteButton" ] []


displaySetEntry : Model -> String -> String -> Bool -> List (Html Msg)
displaySetEntry model path style locked =
    let
        plat =
            platform model

        name =
            Path.takeFileName plat path

        dir =
            Path.takeDirectory plat path
    in
        [ div [ class "fileAction" ]
            [ (displaySetAction model path locked)
            ]
        , div [ class ("fileIcon " ++ style) ] [ img [ src "images/file-icon.png" ] [] ]
        , div [ class "fileName" ]
            [ span [ class "fileNameText" ] [ text name ]
            ]
        , div [ class "filePath" ] [ text dir ]
        ]


displaySetEntries : Model -> List (Maybe String) -> String -> Bool -> List (Html Msg)
displaySetEntries model maybePaths style locked =
    let
        paths =
            List.filterMap identity maybePaths
    in
        paths
            |> List.foldl (\v acc -> acc ++ (displaySetEntry model v style locked)) []


shouldLock : Model -> Array String -> Bool
shouldLock model paths =
    Array.filter (\v -> Set.member v model.deleted |> not) paths
        |> Array.length
        |> (>=) 1


displaySet : DisplaySet -> List (Html Msg)
displaySet dset =
    let
        paths =
            Set.toList dset.paths |> Array.fromList

        locked =
            shouldLock dset.model paths

        n =
            Array.length paths

        first =
            Array.get 0 paths

        middle =
            Array.slice 1 -1 paths
                |> Array.toList
                |> List.map (\v -> Just v)
    in
        if n == 1 then
            displaySetEntries dset.model [ first ] "onlyIcon" locked
        else
            displaySetEntries dset.model [ first ] "firstIcon" locked
                ++ displaySetEntries dset.model middle "middleIcon" locked
                ++ displaySetEntries dset.model [ Array.get (n - 1) paths ] "lastIcon" locked


displaySets : Model -> List (Html Msg)
displaySets model =
    toDisplay model
        |> List.foldl (\v acc -> acc ++ (displaySet v)) []


toDisplay : Model -> List DisplaySet
toDisplay model =
    let
        hashes =
            selectedHashes model

        hd =
            hashDisplays model hashes
    in
        hd
            ++ [ { model = model
                 , paths = model.hashing
                 }
               ]


hashDisplays : Model -> StringSet -> List DisplaySet
hashDisplays model selected =
    Set.toList selected
        |> List.map
            (\hash ->
                { model = model
                , paths = pathsByHash model hash
                }
            )


pathsByHash : Model -> String -> StringSet
pathsByHash model hash =
    case (Dict.get hash model.hashToPaths) of
        Nothing ->
            Set.empty

        Just paths ->
            paths


selectedHashes : Model -> StringSet
selectedHashes model =
    case model.selected of
        Nothing ->
            Set.empty

        Just size ->
            Dict.get size model.sizeToHashes
                |> Maybe.withDefault Set.empty


formatSize : Int -> String
formatSize k =
    if k > 1000000000 then
        format usLocale (toFloat k / 1000000000.0) ++ " GB"
    else if k > 1000000 then
        format usLocale (toFloat k / 1000000.0) ++ " MB"
    else if k > 1000 then
        format usLocale (toFloat k / 1000.0) ++ " KB"
    else
        toString k ++ " B"


numFilesChecked : Dict Int StringSet -> String
numFilesChecked bySize =
    -- count the non-empty files checked so far
    Dict.foldl (\k v acc -> acc + (Set.size v)) 0 bySize
        |> toString
