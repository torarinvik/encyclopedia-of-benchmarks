from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("absolute_min_benchmark")
fn absolute_min_benchmark(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 257:
        return -1
    let n = input[0]
    if n < 1 or n > 256 or length != c_size_t(n + 1):
        return -1
    for i in range(1, length):
        if input[i] < -1000000000 or input[i] > 1000000000:
            return -1
    var best = input[1]
    for i in range(2, length):
        let x = input[i]
        var ax = x
        var ab = best
        if ax < 0:
            ax = -ax
        if ab < 0:
            ab = -ab
        if ax < ab or (ax == ab and x < best):
            best = x
    return best
