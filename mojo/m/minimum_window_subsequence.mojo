from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_INPUT_LENGTH = 258

@export("minimum_window_subsequence")
fn minimum_window_subsequence(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t,
                              out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 3 or n > MAX_INPUT_LENGTH: return -1
    if v[0] < 0 or v[0] > 128: return -1
    let search_length = Int(v[0])
    let pattern_length_index = search_length + 1
    if Int(n) <= pattern_length_index: return -1
    let pattern_length_value = v[pattern_length_index]
    if pattern_length_value < 1 or pattern_length_value > 128: return -1
    let pattern_length = Int(pattern_length_value)
    if Int(n) != search_length + pattern_length + 2: return -1
    for i in range(search_length):
        if v[i + 1] < 0 or v[i + 1] > 127: return -1
    for j in range(pattern_length):
        if v[search_length + 2 + j] < 0 or v[search_length + 2 + j] > 127: return -1

    var latest_start = InlineArray[Int8, 128](fill=Int8(-1))
    var best_start = -1
    var best_length = search_length + 1
    for end in range(search_length):
        let byte = v[end + 1]
        for offset in range(pattern_length):
            let pattern_index = pattern_length - 1 - offset
            if byte != v[search_length + 2 + pattern_index]: continue
            let candidate = end if pattern_index == 0 else Int(latest_start[pattern_index - 1])
            if candidate >= 0 and candidate > Int(latest_start[pattern_index]):
                latest_start[pattern_index] = Int8(candidate)
        if byte == v[search_length + 2 + pattern_length - 1] and Int(latest_start[pattern_length - 1]) >= 0:
            let start = Int(latest_start[pattern_length - 1])
            let window_length = end - start + 1
            if window_length < best_length or (window_length == best_length and (best_start < 0 or start < best_start)):
                best_start = start
                best_length = window_length
    if best_start < 0: return 0
    if best_length > Int(cap) or out == UnsafePointer[UInt8, MutAnyOrigin](): return -2
    for i in range(best_length):
        out[i] = UInt8(v[best_start + 1 + i])
    return Int64(best_length)
