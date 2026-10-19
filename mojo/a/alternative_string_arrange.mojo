from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("alternative_string_arrange")
fn alternative_string_arrange(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                              output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or input[0] < 0 or input[0] > 64: return -1
    let a = Int(input[0])
    if a + 1 >= Int(length) or input[1 + a] < 0 or input[1 + a] > 64: return -1
    let b = Int(input[1 + a])
    if length != c_size_t(2 + a + b): return -1
    for i in range(a):
        if input[1 + i] < 0 or input[1 + i] > 127: return -1
    for i in range(b):
        if input[2 + a + i] < 0 or input[2 + a + i] > 127: return -1
    let count = a + b
    if capacity < c_size_t(count) or (count > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    var written = 0
    for i in range(max(a, b)):
        if i < a:
            output[written] = UInt8(input[1 + i]); written += 1
        if i < b:
            output[written] = UInt8(input[2 + a + i]); written += 1
    return Int64(written)
