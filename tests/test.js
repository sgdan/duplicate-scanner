load("web/hash.js")

var actual = md5sum("tests/toHash.txt")
var expected = "e97ffb87f3d2aa73a7ed21d7dc88b2eb"

if (actual != expected) throw "Expected " + expected + " but was " + actual
