module Main exposing (..)

import Model exposing (..)
import View exposing (view)
import Update exposing (update)
import Ports exposing (..)
import Html exposing (..)


main : Program Never Model Msg
main =
    program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


init : ( Model, Cmd Msg )
init =
    ( emptyModel, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ addDir DirAdded
        , addFile FileAdded
        , addHash HashAdded
        ]
