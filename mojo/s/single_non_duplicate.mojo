from std.ffi import c_size_t
from std.memory import Pointer
from std.origin import ImmUntrackedOrigin


@export("single_non_duplicate")
def single_non_duplicate(values: Pointer[Int64, ImmUntrackedOrigin], length: c_size_t) abi("C") -> Int64:
    if length == 0 or length > 1025 or length % 2 == 0:
        return -2147483649
    var left = 0
    var right = Int(length) // 2
    while left < right:
        var middle = left + (right - left) // 2
        if values[middle * 2] == values[middle * 2 + 1]:
            left = middle + 1
        else:
            right = middle
    return values[left * 2]
