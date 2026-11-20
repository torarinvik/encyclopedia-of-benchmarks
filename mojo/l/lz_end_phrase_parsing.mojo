from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_TEXT = 64
comptime MAX_INPUT = 66
comptime PHRASE_MULTIPLIER = 133121

@export("lz_end_phrase_parsing")
fn lz_end_phrase_parsing(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT: return -1
    let nv = input[0]
    if nv < 0 or nv > MAX_TEXT or length != c_size_t(nv + 1): return -1
    let n = Int(nv)
    for i in range(n):
        if input[1 + i] < 0 or input[1 + i] > 255: return -1
    var boundaries = InlineArray[Int, MAX_TEXT](fill=0)
    var phraseLengths = InlineArray[Int, MAX_TEXT](fill=0)
    var phrases = 0
    var position = 0
    while position < n:
        let remaining = n - position
        var bestCopy = 0
        var copyLength = remaining - 1
        while copyLength > 0 and bestCopy == 0:
            var prior = phrases - 1
            while prior >= 0 and bestCopy == 0:
                let boundary = boundaries[prior]
                if boundary >= copyLength:
                    var matches = True
                    for offset in range(copyLength):
                        if input[1 + position + offset] != input[1 + boundary - copyLength + offset]:
                            matches = False
                            break
                    if matches: bestCopy = copyLength
                prior -= 1
            copyLength -= 1
        phraseLengths[phrases] = bestCopy + 1
        position += phraseLengths[phrases]
        boundaries[phrases] = position
        phrases += 1
    var checksum: Int64 = 0
    for i in range(phrases): checksum += Int64(i + 1) * Int64(phraseLengths[i])
    Int64(PHRASE_MULTIPLIER) * Int64(phrases) + checksum
