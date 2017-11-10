module View exposing (view)

import Model exposing (..)
import Html exposing (..)
import Html.Events exposing (on, onClick, onInput, targetValue)
import Html.Attributes exposing (..)
import Dict exposing (Dict)
import Set exposing (Set)
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (usLocale)
import Json.Decode as Json


view : Model -> Html Msg
view model =
    div []
        [ Set.toList model.dirs |> folderList
        , fieldset [ defaultStyle ]
            [ button [ buttonStyle, onClick OpenFolder ] [ text "Open Folder" ]
            , button [ onClick Clear ] [ text "Clear" ]
            ]
        , div [] [ text ("Checked: " ++ (numFilesChecked model.sizeToPaths)) ]
        , br [] []
        , div []
            [ text "Potential duplicates by file size:"
            , select [ selectStyle, onChange SelectSize ] <| sizesList model <| sameSize model
            ]
        , br [] []
        , resultsTableOrNot model
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


resultsTableOrNot : Model -> Html Msg
resultsTableOrNot model =
    case model.selected of
        Nothing ->
            text "Nothing selected"

        Just size ->
            resultsTable size model


resultsTable : Int -> Model -> Html Msg
resultsTable size model =
    let
        files =
            List.foldl (\v acc -> List.append acc (pathSetDisplay v)) [] <|
                toDisplay model
    in
        div [ divTable ]
            [ div [ divTableBody ]
                files
            ]


pathSetDisplay : DisplaySet -> List (Html Msg)
pathSetDisplay ds =
    let
        pathList =
            Set.toList ds.paths
    in
        div [ divTableRow ]
            [ div [ defaultStyle ] [ br [] [] ] ]
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
                button [ buttonStyle, onClick (DeleteFile path) ] [ text "Delete" ]
            else if Set.member path model.hashing then
                div [ defaultStyle ] [ text "Hashing..." ]
            else
                div [ defaultStyle ] [ text "" ]

        cell =
            if showDelete then
                divTableCell
            else
                deletedTableCell
    in
        div [ divTableRow ]
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


sizeOption : Int -> Int -> Bool -> Html msg
sizeOption bytes n isSelected =
    option [ toString bytes |> value, selected isSelected ]
        [ toString n ++ " files of size " ++ formatSize bytes |> text ]


wasSelected : Int -> Model -> Bool
wasSelected size model =
    case model.selected of
        Nothing ->
            False

        Just val ->
            val == size


sizesList : Model -> Dict Int StringSet -> List (Html msg)
sizesList model entries =
    -- first item blank
    option [ value "" ] [ text "" ]
        :: (Dict.foldl
                (\k v acc ->
                    sizeOption k (Set.size v) (wasSelected k model)
                        :: acc
                )
                []
                entries
           )


folderList : List String -> Html msg
folderList entries =
    case entries of
        [] ->
            text ""

        _ ->
            div []
                [ text "Folders opened:"
                , List.map (\x -> li [] [ text x ]) entries |> ul []
                ]


onChange : (String -> msg) -> Attribute msg
onChange value =
    on "change" (Json.map value targetValue)



-- Count the number of non-empty files checked so far


numFilesChecked : Dict Int StringSet -> String
numFilesChecked bySize =
    Dict.foldl (\k v acc -> acc + (Set.size v)) 0 bySize
        |> toString



{--
   Return only entries where there's more than one file. We only want to
   compute hash values for files that are the same size.
--}


sameSize : Model -> Dict Int StringSet
sameSize model =
    Dict.filter (\k v -> (Set.size v) > 1) model.sizeToPaths


defaultStyle : Attribute msg
defaultStyle =
    style
        [ ( "width", "100%" )
        , ( "height", "40px" )
        , ( "padding", "10px" )
        , ( "font-size", "1em" )
        , ( "border", "0" )
        ]


buttonStyle : Attribute msg
buttonStyle =
    style
        [ ( "margin", "10px" )
        ]


selectStyle : Attribute msg
selectStyle =
    style
        [ ( "border", "1" )
        , ( "width", "100%" )
        ]


divTable : Attribute msg
divTable =
    style [ ( "display", "table" ), ( "width", "100%" ) ]


divTableRow : Attribute msg
divTableRow =
    style [ ( "display", "table-row" ) ]


divTableCell : Attribute msg
divTableCell =
    style
        [ ( "border", "1px solid #999999" )
        , ( "background", "#aaa" )
        , ( "display", "table-cell" )
        , ( "padding", "3px 10px" )
        ]


deletedTableCell : Attribute msg
deletedTableCell =
    style
        [ ( "border", "1px solid #999999" )
        , ( "background", "#faa" )
        , ( "display", "table-cell" )
        , ( "padding", "3px 10px" )
        ]


divTableBody : Attribute msg
divTableBody =
    style
        [ ( "display", "table-row-group" )
        ]
