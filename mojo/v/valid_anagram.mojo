from std.ffi import c_size_t
from std.memory import Pointer
from std.origin import ImmUntrackedOrigin


@export("valid_anagram")
def valid_anagram(
    values: Optional[Pointer[Int64, ImmUntrackedOrigin]], length: c_size_t
) abi("C") -> Int64:
    if values == None or length < 2 or length > 2050:
        return -1
    var input = values.value()
    var first = UInt64(input[unsafe_offset=0])
    var second = UInt64(input[unsafe_offset=1])
    if first > 1024 or second > 1024 or UInt64(length) != 2 + first + second:
        return -1
    if first != second:
        for i in range(2, Int(length)):
            if UInt64(input[unsafe_offset=i]) - 97 > 25:
                return -1
        return 0

    var storage = Array[UInt16, 26](fill=0)
    var counts = storage.unsafe_ptr()
    var count = Int(first)
    for i in range(2, 2 + count):
        var left = UInt64(input[unsafe_offset=i]) - 97
        var right = UInt64(input[unsafe_offset=i + count]) - 97
        if left > 25 or right > 25:
            return -1
        if left != right:
            counts[unsafe_offset=Int(left)] += 1
            counts[unsafe_offset=Int(right)] -= 1
    for slot in range(26):
        if counts[unsafe_offset=slot] != 0:
            return 0
    return 1
