from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn weighted_power(base: Int64, exponent: Int) -> Int64:
    var value: Int64 = 1
    for _ in range(exponent): value *= base
    return value

@export("weighted_random_sampling")
fn weighted_random_sampling(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 50: return -1
    let nv = input[0]; let mv = input[1]
    if nv < 1 or nv > 16 or mv < 1 or mv > nv or length != c_size_t(2 + 3 * nv): return -1
    let n = Int(nv); let m = Int(mv)
    var weights = InlineArray[Int, 16](fill=0)
    var numerator = InlineArray[Int64, 16](fill=0)
    var denominator = InlineArray[Int64, 16](fill=0)
    var available = InlineArray[Int, 16](fill=0)
    for i in range(n):
        let w = input[2 + 3 * i]; let a = input[3 + 3 * i]; let b = input[4 + 3 * i]
        if w < 1 or w > 3 or a < 1 or a >= b or b > 100: return -1
        weights[i] = Int(w); numerator[i] = a; denominator[i] = b; available[i] = i
    let bytes = 8 * m
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var chosen = InlineArray[Int, 16](fill=0)
    for rank in range(m):
        var best = 0
        for i in range(1, n - rank):
            let a = available[i]; let b = available[best]
            let left = weighted_power(numerator[a], weights[b]) * weighted_power(denominator[b], weights[a])
            let right = weighted_power(numerator[b], weights[a]) * weighted_power(denominator[a], weights[b])
            if left > right or (left == right and a < b): best = i
        chosen[rank] = available[best]
        for i in range(best, n - rank - 1): available[i] = available[i + 1]
    for i in range(m):
        var bits = UInt64(chosen[i])
        for byte in range(8):
            output[8 * i + byte] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
