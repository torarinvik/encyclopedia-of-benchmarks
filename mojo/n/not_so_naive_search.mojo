from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_TEXT = 512
comptime MIN_PATTERN = 2
comptime MAX_PATTERN = 64
comptime MAX_INPUT = 578

@export("not_so_naive_search")
fn not_so_naive_search(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT): return -2
    let raw_text = values[0]
    let raw_pattern = values[1]
    if raw_text < 0 or raw_text > MAX_TEXT or raw_pattern < MIN_PATTERN or raw_pattern > MAX_PATTERN: return -2
    let text_length = Int(raw_text)
    let pattern_length = Int(raw_pattern)
    if length != c_size_t(2 + text_length + pattern_length): return -2
    let pattern_start = 2 + text_length
    for i in range(text_length + pattern_length):
        let byte = values[2 + i]
        if byte < 0 or byte > 127: return -2
    if pattern_length > text_length: return -1

    let same_prefix = values[pattern_start] == values[pattern_start + 1]
    let mismatch_shift = if same_prefix: 2 else: 1
    let post_check_shift = if same_prefix: 1 else: 2
    var position = 0
    let last_start = text_length - pattern_length
    while position <= last_start:
        if values[pattern_start + 1] != values[2 + position + 1]:
            position += mismatch_shift
            continue
        var pattern_index = 2
        while pattern_index < pattern_length and values[pattern_start + pattern_index] == values[2 + position + pattern_index]:
            pattern_index += 1
        if pattern_index == pattern_length and values[pattern_start] == values[2 + position]:
            return Int64(position)
        position += post_check_shift
    return -1
