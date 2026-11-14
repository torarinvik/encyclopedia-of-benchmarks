from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("tsvc_s3111_positive_value_sum")
fn tsvc_s3111_positive_value_sum(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 65: return -1
    let n = input[0]
    if n < 0 or n > 64 or length != c_size_t(n + 1): return -1
    var total = Int64(0)
    for i in range(Int(n)):
        let value = input[i + 1]
        if value < -1_000_000 or value > 1_000_000: return -1
        if value > 0: total += value
    return total
