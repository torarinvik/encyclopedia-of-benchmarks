from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("federated_averaging")
fn federated_averaging(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 17: return -1.0e300
    let n = input[0]
    if n < 1 or n > 8 or length != 1 + 2 * n: return -1.0e300
    var total = 0.0
    for i in range(n):
        let w = input[1 + i]
        if w < 0 or w > 1000: return -1.0e300
        total += Float64(w)
    if total <= 0.0: return -1.0e300
    var result = 0.0
    for i in range(n):
        let x = input[1 + n + i]
        if x < -1000 or x > 1000: return -1.0e300
        let normalized = Float64(input[1 + i]) / total
        result += normalized * Float64(x)
    return result
