from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_TEXT = 4096
comptime MAX_PATTERN = 128
comptime MAX_INPUT_LENGTH = 4227
comptime ALPHABET = 4

fn maximal_shift_match_shift(pattern: InlineArray[UInt8, MAX_PATTERN],
        order_loc: InlineArray[Int, MAX_PATTERN + 1],
        order_symbol: InlineArray[Int, MAX_PATTERN + 1], m: Int,
        prefix_length: Int, initial_shift: Int) -> Int:
    var shift = initial_shift
    while shift < m:
        var order_index = prefix_length - 1
        while order_index >= 0:
            let pattern_index = order_loc[order_index] - shift
            if pattern_index >= 0 and order_symbol[order_index] != Int(pattern[pattern_index]):
                break
            order_index -= 1
        if order_index < 0:
            break
        shift += 1
    return shift

@export("maximal_shift_search")
fn maximal_shift_search(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_LENGTH:
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
        if value < 0 or value >= ALPHABET:
            return -1
        text[q] = UInt8(value)
    for q in range(m):
        let value = input[2 + n + q]
        if value < 0 or value >= ALPHABET:
            return -1
        pattern[q] = UInt8(value)
    if n < m:
        return 0

    var leading_shift = InlineArray[Int, MAX_PATTERN](fill=0)
    var order_loc = InlineArray[Int, MAX_PATTERN + 1](fill=0)
    var order_symbol = InlineArray[Int, MAX_PATTERN + 1](fill=0)
    var quick_shift = InlineArray[Int, ALPHABET](fill=m + 1)
    var adapted_shift = InlineArray[Int, MAX_PATTERN + 1](fill=0)
    for i in range(m):
        var previous = i - 1
        while previous >= 0 and pattern[previous] != pattern[i]:
            previous -= 1
        leading_shift[i] = i - previous
        var position = i
        while position > 0:
            let prior_loc = order_loc[position - 1]
            if leading_shift[prior_loc] > leading_shift[i] or
                (leading_shift[prior_loc] == leading_shift[i] and prior_loc > i):
                break
            order_loc[position] = prior_loc
            position -= 1
        order_loc[position] = i
    for i in range(m):
        order_symbol[i] = Int(pattern[order_loc[i]])
    order_loc[m] = m
    order_symbol[m] = -1
    for i in range(m):
        quick_shift[Int(pattern[i])] = m - i

    var shift = 1
    adapted_shift[0] = 1
    for prefix_length in range(1, m + 1):
        shift = maximal_shift_match_shift(pattern, order_loc, order_symbol, m, prefix_length, shift)
        adapted_shift[prefix_length] = shift
    for prefix_length in range(m + 1):
        shift = adapted_shift[prefix_length]
        while shift < m:
            let pattern_index = order_loc[prefix_length] - shift
            if pattern_index < 0 or order_symbol[prefix_length] != Int(pattern[pattern_index]):
                break
            shift += 1
            shift = maximal_shift_match_shift(pattern, order_loc, order_symbol, m, prefix_length, shift)
        adapted_shift[prefix_length] = shift

    var count: Int64 = 0
    var offset_sum: Int64 = 0
    var offset_xor: Int64 = 0
    var start = 0
    while start <= n - m:
        var compared = 0
        while compared < m and order_symbol[compared] == Int(text[start + order_loc[compared]]):
            compared += 1
        if compared == m:
            count += 1
            offset_sum += Int64(start)
            offset_xor ^= Int64(start)
        let lookahead = start + m
        if lookahead >= n:
            break
        start += max(adapted_shift[compared], quick_shift[Int(text[lookahead])])
    return (count << 36) | (offset_sum << 12) | offset_xor
