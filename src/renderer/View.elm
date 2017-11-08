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
        , div [] [ text ("Number of files checked: " ++ (numFilesChecked model.bySize)) ]
        , div [] [ text ("Hashing: " ++ (toString (model.hashing))) ]
        , div [] [ text ("byHash: " ++ (toString (Dict.size model.byHash))) ]
        , div []
            [ text "Selected: "
            , text (toString model.selected)
            ]
        , br [] []
        , div []
            [ text "Potential duplicates by file size:"
            , --text toString model.selected, -- targetValue is Json.Decoder String
              select [ selectStyle, onChange SelectSize ] (sizesList (sameSize model.bySize))
            ]
        , br [] []
        , div []
            [ div [] [ text "Hashing..." ]
            , div [] [ text "Group 1" ]
            , div [] [ text "Group 2" ]
            ]
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


sizeOption : Int -> Html msg
sizeOption bytes =
    option [ toString bytes |> value ]
        [ formatSize bytes |> text ]


sizesList : Dict Int PathSet -> List (Html msg)
sizesList entries =
    -- first item blank
    option [ value "" ] [ text "" ]
        :: (Dict.foldl
                (\k v acc ->
                    sizeOption k
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


numFilesChecked : Dict Int PathSet -> String
numFilesChecked bySize =
    Dict.foldl (\k v acc -> acc + (Set.size v)) 0 bySize
        |> toString



{--
    Return only entries where there's more than one file. We only want to
    compute hash values for files that are the same size.
--}


sameSize : Dict Int PathSet -> Dict Int PathSet
sameSize entries =
    Dict.filter (\k v -> (Set.size v) > 1) entries


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
