var FileInputStream = java.io.FileInputStream
var DigestInputStream = java.security.DigestInputStream
var MessageDigest = java.security.MessageDigest
var BigInteger = java.math.BigInteger
var ByteArray = Java.type("byte[]")

function md5sum(path) {
    var md = MessageDigest.getInstance("MD5")
    var dis = new DigestInputStream(new FileInputStream(path), md)
    var buf = new ByteArray(8192)
    var n = dis.read(buf)
    while (n > 0) n = dis.read(buf, 0, 8192)
    dis.close()
    return new BigInteger(1, md.digest()).toString(16)
}