from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("bead_sort")
fn bead_sort(values: UnsafePointer[Int64, MutAnyOrigin], scratch: UnsafePointer[Int64, MutAnyOrigin],
             length: c_size_t) abi("C") -> None:
    if length < 2: return
    for level in range(64): scratch[level] = 0
    for index in range(length):
        for level in range(values[index]):
            scratch[level] += 1
    for index in range(length):
        let row_from_bottom = Int64(length - 1 - index)
        var value: Int64 = 0
        for level in range(64):
            if scratch[level] > row_from_bottom: value += 1
        values[index] = value
