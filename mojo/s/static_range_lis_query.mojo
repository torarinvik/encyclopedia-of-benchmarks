from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 128
comptime MAX_Q = 32
comptime MAX_INPUT = 195

fn write_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & UInt64(255))

@export("static_range_lis_query")
fn static_range_lis_query(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT):
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 1 or q_value > MAX_Q:
        return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if length != c_size_t(2 + n + 2 * q):
        return -1
    var permutation = InlineArray[Int64, MAX_N]()
    var seen = InlineArray[Bool, MAX_N]()
    var left = InlineArray[Int64, MAX_Q]()
    var right = InlineArray[Int64, MAX_Q]()
    var answers = InlineArray[Int64, MAX_Q]()
    var tails = InlineArray[Int64, MAX_N]()
    for i in range(n):
        let value = input[2 + i]
        if value < 0 or value >= n_value or seen[Int(value)]:
            return -1
        seen[Int(value)] = True
        permutation[i] = value
    var offset = 2 + n
    for k in range(q):
        left[k] = input[offset]
        right[k] = input[offset + 1]
        offset += 2
        if left[k] < 0 or left[k] > right[k] or right[k] > n_value:
            return -1
    for k in range(q):
        var count = 0
        for i in range(Int(left[k]), Int(right[k])):
            let value = permutation[i]
            var lo = 0
            var hi = count
            while lo < hi:
                let mid = lo + (hi - lo) // 2
                if tails[mid] < value:
                    lo = mid + 1
                else:
                    hi = mid
            tails[lo] = value
            if lo == count:
                count += 1
        answers[k] = Int64(count)
    let bytes = 8 * q
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes):
        return -2
    for k in range(q):
        write_i64_le(output, 8 * k, answers[k])
    return Int64(bytes)
