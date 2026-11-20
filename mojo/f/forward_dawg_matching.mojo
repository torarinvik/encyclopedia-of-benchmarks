from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_TEXT = 4096
comptime MAX_PATTERN = 128
comptime MAX_INPUT = 4227
comptime MAX_STATES = 2 * MAX_PATTERN + 2

@export("forward_dawg_matching")
fn forward_dawg_matching(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT: return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 0 or n_value > MAX_TEXT or m_value < 1 or m_value > MAX_PATTERN: return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if Int(length) != 2 + n + m: return -1
    for index in range(n + m):
        let value = input[2 + index]
        if value < 0 or value > 3: return -1

    var pattern = InlineArray[Int64, MAX_PATTERN](fill=0)
    for index in range(m): pattern[index] = input[2 + n + index]
    var transition = InlineArray[Int64, MAX_STATES * 4](fill=-1)
    var suffix_link = InlineArray[Int64, MAX_STATES](fill=-1)
    var max_length = InlineArray[Int64, MAX_STATES](fill=0)
    var state_count = 1
    var last = 0

    for index in range(m):
        if state_count >= MAX_STATES: return -1
        let current = state_count
        state_count += 1
        let symbol = Int(pattern[index])
        max_length[current] = max_length[last] + 1
        var state = last
        while state >= 0 and transition[state * 4 + symbol] < 0:
            transition[state * 4 + symbol] = Int64(current)
            state = Int(suffix_link[state])
        if state < 0:
            suffix_link[current] = 0
        else:
            let target = transition[state * 4 + symbol]
            if max_length[state] + 1 == max_length[Int(target)]:
                suffix_link[current] = target
            else:
                if state_count >= MAX_STATES: return -1
                let clone = state_count
                state_count += 1
                max_length[clone] = max_length[state] + 1
                suffix_link[clone] = suffix_link[Int(target)]
                for c in range(4):
                    transition[clone * 4 + c] = transition[Int(target) * 4 + c]
                while state >= 0 and transition[state * 4 + symbol] == target:
                    transition[state * 4 + symbol] = Int64(clone)
                    state = Int(suffix_link[state])
                suffix_link[Int(target)] = Int64(clone)
                suffix_link[current] = Int64(clone)
        last = current

    var state = 0
    var matched: Int64 = 0
    var count: Int64 = 0
    var offset_sum: Int64 = 0
    var offset_xor: Int64 = 0
    for position in range(n):
        let symbol = Int(input[2 + position])
        var target = transition[state * 4 + symbol]
        if target >= 0:
            matched += 1
            state = Int(target)
        else:
            while state != 0 and transition[state * 4 + symbol] < 0:
                state = Int(suffix_link[state])
            target = transition[state * 4 + symbol]
            if target >= 0:
                matched = max_length[state] + 1
                state = Int(target)
            else:
                matched = 0
                state = 0
        if matched == Int64(m):
            let start = Int64(position + 1 - m)
            count += 1
            offset_sum += start
            offset_xor = offset_xor ^ start
    (count << 36) | (offset_sum << 12) | offset_xor
