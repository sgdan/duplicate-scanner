module Main exposing (..)

import Model exposing (..)
import View exposing (view)
import Update exposing (update)
import Ports exposing (..)
import Html exposing (..)


type alias Flags =
    { isWindows : Bool
    }


main : Program Flags Model Msg
main =
    programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( emptyModel flags.isWindows, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ addDir DirAdded
        , addFile FileAdded
        , addHash HashAdded
        , fileDeleted FileDeleted
        ]
