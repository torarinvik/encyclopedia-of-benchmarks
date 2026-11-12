from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

const MAX_Q = 8
const MAX_N = 10_000
const MAX_OUTPUT_BYTES = 6_496

fn integer_sqrt(value: Int64) -> Int64:
    var low: Int64 = 0
    var high = value + 1
    while high - low > 1:
        let middle = low + (high - low) // 2
        if middle * middle <= value: low = middle
        else: high = middle
    return low

fn write_u32(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: UInt32):
    output[offset] = UInt8(value & UInt32(255))
    output[offset + 1] = UInt8((value >> 8) & UInt32(255))
    output[offset + 2] = UInt8((value >> 16) & UInt32(255))
    output[offset + 3] = UInt8((value >> 24) & UInt32(255))

@export("two_square_sum")
fn two_square_sum(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                  output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(2) or length > c_size_t(MAX_Q + 1): return -1
    let q_value = input[0]
    if q_value < 1 or q_value > MAX_Q: return -1
    let q = Int(q_value)
    if Int(length) != q + 1: return -1

    var numbers = InlineArray[Int64, MAX_Q](fill=0)
    var counts = InlineArray[Int, MAX_Q](fill=0)
    var total_pairs = 0
    for query in range(q):
        let n = input[query + 1]
        if n < 0 or n > MAX_N: return -1
        numbers[query] = n
        var a: Int64 = 0
        while a * a <= n:
            let remainder = n - a * a
            let b = integer_sqrt(remainder)
            if b * b == remainder: counts[query] += 1
            a += 1
        total_pairs += counts[query]

    let required = 4 * (q + 2 * total_pairs)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required) or required > MAX_OUTPUT_BYTES: return -2
    var offset = 0
    for query in range(q):
        write_u32(output, offset, UInt32(counts[query]))
        offset += 4
        let n = numbers[query]
        var a: Int64 = 0
        while a * a <= n:
            let remainder = n - a * a
            let b = integer_sqrt(remainder)
            if b * b == remainder:
                write_u32(output, offset, UInt32(a))
                write_u32(output, offset + 4, UInt32(b))
                offset += 8
            a += 1
    return Int64(offset)
