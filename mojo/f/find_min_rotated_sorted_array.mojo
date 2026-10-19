from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("find_min_rotated_sorted_array")
fn find_min_rotated_sorted_array(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length < 1 or length > 256 or values == UnsafePointer[Int64, ImmutAnyOrigin](): return -1
    var low: Int64 = 0
    var high = Int64(length) - 1
    while low < high:
        let middle = low + (high - low) / 2
        if values[middle] <= values[high]: high = middle
        else: low = middle + 1
    return values[low]
