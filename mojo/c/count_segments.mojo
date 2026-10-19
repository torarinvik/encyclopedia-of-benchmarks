from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("count_segments")
fn count_segments(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 4096 or (length != 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    var count: Int64 = 0
    var previous_was_space = True
    for i in range(length):
        let value = input[i]
        if value < 1 or value > 127: return -1
        if value != 32 and previous_was_space: count += 1
        previous_was_space = value == 32
    return count
