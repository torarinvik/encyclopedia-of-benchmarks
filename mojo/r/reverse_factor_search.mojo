from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_TEXT = 4096
comptime MAX_PATTERN = 128
comptime MAX_INPUT_LENGTH = 4227
comptime MAX_STATES = 2 * MAX_PATTERN + 1

@export("reverse_factor_search")
fn reverse_factor_search(input: UnsafePointer[Int64, ImmutAnyOrigin],
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
        if value < 0 or value > 3:
            return -1
        text[q] = UInt8(value)
    for q in range(m):
        let value = input[2 + n + q]
        if value < 0 or value > 3:
            return -1
        pattern[q] = UInt8(value)
    if n < m:
        return 0

    var transitions = InlineArray[Int, MAX_STATES * 4](fill=-1)
    var suffix_link = InlineArray[Int, MAX_STATES](fill=-1)
    var max_length = InlineArray[Int, MAX_STATES](fill=0)
    var terminal = InlineArray[Bool, MAX_STATES](fill=False)
    var state_count = 1
    var last = 0
    for pos in range(m):
        let symbol = Int(pattern[m - 1 - pos])
        let current = state_count
        state_count += 1
        max_length[current] = max_length[last] + 1
        var predecessor = last
        while predecessor >= 0 and transitions[predecessor * 4 + symbol] < 0:
            transitions[predecessor * 4 + symbol] = current
            predecessor = suffix_link[predecessor]
        if predecessor < 0:
            suffix_link[current] = 0
        else:
            let target = transitions[predecessor * 4 + symbol]
            if max_length[predecessor] + 1 == max_length[target]:
                suffix_link[current] = target
            else:
                let clone = state_count
                state_count += 1
                for symbol_index in range(4):
                    transitions[clone * 4 + symbol_index] = transitions[target * 4 + symbol_index]
                max_length[clone] = max_length[predecessor] + 1
                suffix_link[clone] = suffix_link[target]
                while predecessor >= 0 and transitions[predecessor * 4 + symbol] == target:
                    transitions[predecessor * 4 + symbol] = clone
                    predecessor = suffix_link[predecessor]
                suffix_link[target] = clone
                suffix_link[current] = clone
        last = current
    var terminal_state = last
    while terminal_state >= 0:
        terminal[terminal_state] = True
        terminal_state = suffix_link[terminal_state]

    var count: Int64 = 0
    var offset_sum: Int64 = 0
    var offset_xor: Int64 = 0
    var period = m
    var start = 0
    while start <= n - m:
        var index = m - 1
        var state = 0
        var shift = m
        while start + index >= 0:
            let symbol = Int(text[start + index])
            let target = transitions[state * 4 + symbol]
            if target < 0:
                break
            state = target
            if terminal[state]:
                period = shift
                shift = index
            index -= 1
        if index < 0:
            count += 1
            offset_sum += Int64(start)
            offset_xor ^= Int64(start)
            shift = period
        start += shift
    return (count << 36) | (offset_sum << 12) | offset_xor
