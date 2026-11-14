from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("tsvc_s331_last_negative_index")
fn tsvc_s331_last_negative_index(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 257: return -1
    let n = input[0]
    if n < 1 or n > 256 or length != c_size_t(n + 1): return -1
    var result = Int64(0)
    for index in range(Int(n)):
        let value = input[index + 1]
        if value < -1_000_000 or value > 1_000_000: return -1
        if value < 0: result = Int64(index + 1)
    return result
