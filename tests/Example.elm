module Example exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)


suite : Test
suite =
    --todo "Implement our first test. See http://package.elm-lang.org/packages/elm-community/elm-test/latest for how to do this!"
    describe "description"
        [ test "test name" <|
            \_ ->
                let
                    palindrome =
                        "livedirtupsidetrackcartedisputridevil"
                in
                    Expect.equal palindrome (String.reverse palindrome)
        ]
