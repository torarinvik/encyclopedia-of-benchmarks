from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_TEXT = 4096
const MAX_PATTERN = 128
const MAX_INPUT = 4227

@export("morris_pratt_search")
fn morris_pratt_search(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT:
        return -1
    let raw_n = input[0]
    let raw_m = input[1]
    if raw_n < 0 or raw_n > MAX_TEXT or raw_m < 1 or raw_m > MAX_PATTERN:
        return -1
    let n = Int(raw_n)
    let m = Int(raw_m)
    if length != c_size_t(2 + n + m): return -1
    let pattern_start = 2 + n
    for q in range(n + m):
        if input[2 + q] < 0 or input[2 + q] > 3: return -1

    var mp_next = InlineArray[Int64, 129](fill=0)
    mp_next[0] = -1
    for index in range(m):
        var border = Int(mp_next[index])
        while border >= 0 and input[pattern_start + index] != input[pattern_start + border]:
            border = Int(mp_next[border])
        mp_next[index + 1] = Int64(border + 1)

    var matched = 0
    var count: Int64 = 0
    var offset_sum: Int64 = 0
    var offset_xor: Int64 = 0
    for text_index in range(n):
        while matched >= 0 and input[pattern_start + matched] != input[2 + text_index]:
            matched = Int(mp_next[matched])
        matched += 1
        if matched == m:
            let start = Int64(text_index + 1 - matched)
            count += 1
            offset_sum += start
            offset_xor ^= start
            matched = Int(mp_next[m])
    return (count << 36) | (offset_sum << 12) | offset_xor
