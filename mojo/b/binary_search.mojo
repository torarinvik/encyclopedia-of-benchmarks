from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("binary_search")
fn binary_search(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, target: Int64) abi("C") -> Int64:
    var low = 0; var high = Int(length)
    while low < high:
        let mid = low + (high - low) // 2
        let value = values[mid]
        if value == target: return Int64(mid)
        if value < target: low = mid + 1
        else: high = mid
    return -1
