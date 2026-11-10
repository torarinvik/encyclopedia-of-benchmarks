from std.ffi import c_size_t
from std.memory import Pointer
from std.origin import ImmUntrackedOrigin


@export("search_insert_position")
def search_insert_position(values: Pointer[Int64, ImmUntrackedOrigin], length: c_size_t) abi("C") -> Int64:
    if length < 1 or length > 257:
        return -1
    var target = values[0]
    if target < -2147483648 or target > 2147483647:
        return -1

    var previous = Int64(-2147483649)
    for index in range(1, Int(length)):
        var value = values[index]
        if value > 2147483647 or value <= previous:
            return -1
        previous = value

    var low = 0
    var high = Int(length) - 1
    while low < high:
        var middle = low + (high - low) // 2
        if values[middle + 1] < target:
            low = middle + 1
        else:
            high = middle
    return Int64(low)
