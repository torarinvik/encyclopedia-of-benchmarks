from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("lyndon_factorization")
fn lyndon_factorization(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 257: return -1
    let n64 = input[0]
    if n64 < 0 or n64 > 256 or length != c_size_t(n64 + 1): return -1
    let n = Int(n64)
    for i in range(n):
        if input[i + 1] < 97 or input[i + 1] > 122: return -1
    if capacity < c_size_t(2 * n) or (n > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    var start = 0
    var out = 0
    while start < n:
        var candidate = start + 1
        var matched = start
        while candidate < n and input[matched + 1] <= input[candidate + 1]:
            if input[matched + 1] < input[candidate + 1]:
                matched = start
            else:
                matched += 1
            candidate += 1
        let factor_length = candidate - matched
        while start <= matched:
            for j in range(factor_length):
                output[out] = UInt8(input[start + j + 1])
                out += 1
            output[out] = 0
            out += 1
            start += factor_length
    return Int64(out)
