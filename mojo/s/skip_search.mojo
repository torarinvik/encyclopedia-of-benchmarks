from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_TEXT = 4096
const MAX_PATTERN = 128
const MAX_INPUT = 4227

@export("skip_search")
fn skip_search(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT:
        return -1
    let raw_n = input[0]
    let raw_m = input[1]
    if raw_n < 0 or raw_n > MAX_TEXT or raw_m < 1 or raw_m > MAX_PATTERN:
        return -1
    let n = Int(raw_n)
    let m = Int(raw_m)
    if length != c_size_t(2 + n + m):
        return -1

    var text = InlineArray[UInt8, MAX_TEXT](fill=0)
    var pattern = InlineArray[UInt8, MAX_PATTERN](fill=0)
    for q in range(n):
        let value = input[2 + q]
        if value < 0 or value > 3: return -1
        text[q] = UInt8(value)
    var positions = InlineArray[Int, 4 * MAX_PATTERN](fill=0)
    var bucket_sizes = InlineArray[Int, 4](fill=0)
    for q in range(m):
        let value = input[2 + n + q]
        if value < 0 or value > 3: return -1
        let symbol = Int(value)
        pattern[q] = UInt8(value)
        positions[symbol * MAX_PATTERN + bucket_sizes[symbol]] = q
        bucket_sizes[symbol] += 1

    var count: Int64 = 0
    var offset_sum: Int64 = 0
    var offset_xor: Int64 = 0
    var sample = m - 1
    while sample < n:
        let symbol = Int(text[sample])
        for item in range(bucket_sizes[symbol]):
            let pattern_position = positions[symbol * MAX_PATTERN + item]
            let start = sample - pattern_position
            if start < 0 or start > n - m: continue
            var matched = 0
            while matched < m and text[start + matched] == pattern[matched]:
                matched += 1
            if matched == m:
                count += 1
                offset_sum += Int64(start)
                offset_xor ^= Int64(start)
        sample += m
    return (count << 36) | (offset_sum << 12) | offset_xor
