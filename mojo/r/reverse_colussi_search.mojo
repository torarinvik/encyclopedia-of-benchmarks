from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_TEXT = 4096
comptime MAX_PATTERN = 128
comptime MAX_INPUT_LENGTH = 4227

@export("reverse_colussi_search")
fn reverse_colussi_search(input: UnsafePointer[Int64, ImmutAnyOrigin],
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

    var hmin = InlineArray[Int, MAX_PATTERN + 1](fill=0)
    var kmin = InlineArray[Int, MAX_PATTERN](fill=0)
    var rmin = InlineArray[Int, MAX_PATTERN](fill=0)
    var order = InlineArray[Int, MAX_PATTERN](fill=0)
    var good_suffix = InlineArray[Int, MAX_PATTERN + 1](fill=0)
    var bad_character = InlineArray[Int, 4 * (MAX_PATTERN + 1)](fill=0)
    for shift in range(1, m + 1):
        var last_mismatch = shift - 1
        for pos in range(shift, m):
            if pattern[pos] != pattern[pos - shift]:
                last_mismatch = pos
        hmin[shift] = last_mismatch
    var shift = m
    while shift > 0:
        let end = hmin[shift]
        if end != m - 1:
            kmin[end] = shift
        shift -= 1

    var next_boundary = m
    var end = m - 1
    while end >= 0:
        if hmin[end + 1] == end:
            next_boundary = end + 1
        rmin[end] = next_boundary
        end -= 1

    order[0] = m - 1
    var cursor = 0
    for shift in range(1, m + 1):
        let h_end = hmin[shift]
        if h_end != m - 1 and kmin[h_end] == shift:
            cursor += 1
            order[cursor] = h_end
            good_suffix[cursor] = shift
    cursor = m - 1
    end = m - 2
    while end >= 0:
        if kmin[end] == 0:
            order[cursor] = end
            good_suffix[cursor] = rmin[end]
            cursor -= 1
        end -= 1
    good_suffix[m] = rmin[0]

    for symbol in range(4):
        for prior_shift in range(1, m + 1):
            let boundary = m - prior_shift - 1
            for candidate in range(1, m + 1):
                if candidate < m and Int(pattern[m - candidate - 1]) != symbol:
                    continue
                if candidate <= boundary and
                    pattern[m - candidate - prior_shift - 1] != pattern[boundary]:
                    continue
                bad_character[symbol * (MAX_PATTERN + 1) + prior_shift] = candidate
                break

    var count: Int64 = 0
    var offset_sum: Int64 = 0
    var offset_xor: Int64 = 0
    var start = 0
    var shift_state = m
    let last_start = n - m
    while start <= last_start:
        while start <= last_start and pattern[m - 1] != text[start + m - 1]:
            shift_state = bad_character[Int(text[start + m - 1]) * (MAX_PATTERN + 1) + shift_state]
            start += shift_state
        if start > last_start:
            break
        var index = 1
        while index < m and pattern[order[index]] == text[start + order[index]]:
            index += 1
        if index == m:
            count += 1
            offset_sum += Int64(start)
            offset_xor ^= Int64(start)
        shift_state = good_suffix[index]
        start += shift_state
    return (count << 36) | (offset_sum << 12) | offset_xor
