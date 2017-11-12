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
            [ span [ class "alignBottom" ] [ checked model ]
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
            [ button [ onClick <| SelectSize sizeInBytes ] [ text "Select" ]
            ]
        , div [ class "fileIcon" ] [ br [] [], text "FILESET" ]
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
        List.append entry entries


fileSets : Model -> List (Html Msg)
fileSets model =
    sameSize model
        |> Dict.foldl appendEntry []


checked : Model -> Html msg
checked model =
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
        , div [ class "fileIcon" ] [ br [] [], text "FOLDER" ]
        , div [ class "fileName" ]
            [ span [ class "fileNameText" ] [ text name ]
            ]
        , div [ class "filePath" ] [ text dir ]
        ]


folderList : Model -> List (Html msg)
folderList model =
    model.dirs
        |> Set.foldl (\v acc -> List.append acc (folder model v)) []


filePage : Model -> Html Msg
filePage model =
    div []
        [ div [ class "left-margin" ] []
        , div [ class "left-back" ]
            [ button [ onClick Back ] [ text "Back" ]
            , button [ onClick Close ] [ text "Close" ]
            ]
        , div [ class "right-buttons" ]
            [ button [ onClick OpenFolder ] [ text "Safe" ]
            ]
        , div [ class "app-header" ]
            [ h1 [] [ text "Duplicates FilePage" ]
            ]
        , div [ class "files" ]
            [ div [ class "fileAction" ] [ br [] [], button [] [ text "Delete" ] ]
            , div [ class "fileIcon" ] [ br [] [], text "FILE" ]
            , div [ class "fileName" ]
                [ span [ class "fileNameText" ] [ text "File Name" ]
                ]
            , div [ class "filePath" ] [ text "C:\\six\\five\\four\\three\\two\\one" ]
            ]
        ]


type alias DisplaySet =
    { model : Model
    , paths : StringSet
    }


toDisplay : Model -> List DisplaySet
toDisplay model =
    let
        hashes =
            selectedHashes model

        hd =
            hashDisplays model hashes
    in
        List.append hd
            [ { model = model
              , paths = model.hashing
              }
            ]


hashDisplays : Model -> StringSet -> List DisplaySet
hashDisplays model selected =
    (Set.toList selected)
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


resultsTable : Int -> Model -> Html Msg
resultsTable size model =
    let
        files =
            List.foldl (\v acc -> List.append acc (pathSetDisplay v)) [] <|
                toDisplay model
    in
        div [ class "divTable" ]
            [ div [ class "divTableBody" ]
                files
            ]


pathSetDisplay : DisplaySet -> List (Html Msg)
pathSetDisplay ds =
    let
        pathList =
            Set.toList ds.paths
    in
        div [ class "divTableRow" ]
            [ div [] [ br [] [] ] ]
            :: (List.map (\v -> pathRow ds.model v) pathList)


canDelete : Model -> String -> Bool
canDelete model path =
    Set.member path model.deleted
        || Set.member path model.hashing
        |> not


pathRow : Model -> String -> Html Msg
pathRow model path =
    let
        showDelete =
            canDelete model path

        deleteCell =
            if showDelete then
                button [ onClick (DeleteFile path) ] [ text "Delete" ]
            else if Set.member path model.hashing then
                div [] [ text "Hashing..." ]
            else
                div [] [ text "" ]

        cell =
            if showDelete then
                class "normal-cell"
            else
                class "deleted-cell"
    in
        div [ class "divTableRow" ]
            [ div [ cell ] [ deleteCell ]
            , div [ cell ] [ text path ]
            ]


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
