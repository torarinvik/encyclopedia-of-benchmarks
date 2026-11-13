from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 64
comptime MAX_Q = 15
comptime MAX_PARSEABLE = 32
comptime MAX_OUTPUT_BYTES = 120
comptime MODULUS: Int64 = 998244353

fn prefix_value(q: InlineArray[Int64, MAX_Q], prefix: InlineArray[Int64, MAX_Q],
        count: Int, value: Int64) -> Int64:
    if value == 0:
        return 0
    for index in range(count):
        if q[index] == value:
            return prefix[index]
    return 0

@export("dirichlet_convolution_and_prefix_sums")
fn dirichlet_convolution_and_prefix_sums(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > c_size_t(MAX_PARSEABLE):
        return -1
    if input[0] < 1 or input[0] > MAX_N:
        return -1
    let n = Int64(input[0])
    var descending = InlineArray[Int64, MAX_Q](fill=0)
    var count = 0
    var left: Int64 = 1
    while left <= n:
        let value = n / left
        descending[count] = value
        count += 1
        left = n / value + 1
    var q = InlineArray[Int64, MAX_Q](fill=0)
    for index in range(count):
        q[index] = descending[count - 1 - index]
    if length != c_size_t(1 + 2 * count):
        return -1

    var f = InlineArray[Int64, MAX_Q](fill=0)
    var g = InlineArray[Int64, MAX_Q](fill=0)
    for index in range(count):
        f[index] = input[1 + index]
        g[index] = input[1 + count + index]
        if f[index] < 1 or f[index] >= MODULUS or g[index] < 1 or g[index] >= MODULUS:
            return -1

    var results = InlineArray[Int64, MAX_Q](fill=0)
    for out_index in range(count):
        let x = q[out_index]
        var total: Int64 = 0
        var start: Int64 = 1
        while start <= x:
            let quotient = x / start
            let right = x / quotient
            let below = x / (quotient + 1)
            var interval = (prefix_value(q, f, count, right)
                - prefix_value(q, f, count, below)) % MODULUS
            if interval < 0:
                interval += MODULUS
            var q_index = 0
            while q_index < count and q[q_index] != quotient:
                q_index += 1
            if q_index == count:
                return -1
            total = (total + interval * g[q_index]) % MODULUS
            start = right + 1
        results[out_index] = total

    let needed = 8 * count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(needed):
        return -2
    for index in range(count):
        var bits = UInt64(results[index])
        for byte in range(8):
            output[8 * index + byte] = UInt8(bits & 255)
            bits >>= 8
    return Int64(needed)
