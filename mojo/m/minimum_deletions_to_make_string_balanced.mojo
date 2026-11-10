from std.ffi import c_size_t
from std.memory import Pointer
from std.origin import ImmUntrackedOrigin


@export("minimum_deletions_to_make_string_balanced")
def minimum_deletions_to_make_string_balanced(
    values: Optional[Pointer[Int64, ImmUntrackedOrigin]], length: c_size_t
) abi("C") -> Int64:
    if length > 256 or (length != 0 and values == None):
        return -1

    if length == 0:
        return 0
    var data = values.value()
    var a_state = Int64(0)
    var b_state = Int64(0)
    for index in range(Int(length)):
        var value = data[unsafe_offset=index]
        if value < 0 or value > 1:
            return -1
        if value == 0 and b_state < a_state:
            b_state += 1
        a_state += value
    return b_state
