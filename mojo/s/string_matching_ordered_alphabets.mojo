from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_TEXT = 4096
const MAX_PATTERN = 128
const MAX_INPUT = 4227

fn ordered_alphabets_advance(input: UnsafePointer[Int64, ImmutAnyOrigin], base: Int,
        length: Int, inout left: Int, inout right: Int,
        inout offset: Int, inout period: Int):
    while right + offset < length:
        let a = input[base + left + offset]
        let b = input[base + right + offset]
        if a == b:
            if offset == period:
                right += period
                offset = 1
            else:
                offset += 1
        elif a > b:
            right += offset
            offset = 1
            period = right - left
        else:
            left = right
            right += 1
            offset = 1
            period = 1

fn ordered_alphabets_prefix_repeats(input: UnsafePointer[Int64, ImmutAnyOrigin],
        base: Int, shift: Int, last_index: Int) -> Bool:
    for q in range(last_index + 1):
        if input[base + q] != input[base + shift + q]: return False
    return True

@export("string_matching_ordered_alphabets")
fn string_matching_ordered_alphabets(input: UnsafePointer[Int64, ImmutAnyOrigin],
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
    for q in range(n):
        if input[2 + q] < 0 or input[2 + q] > 3: return -1
    for q in range(m):
        if input[pattern_start + q] < 0 or input[pattern_start + q] > 3: return -1
    if n < m: return 0

    var alignment = 0
    var matched = 0
    var suffix_left = -1
    var suffix_right = 0
    var suffix_offset = 1
    var period = 1
    var count: Int64 = 0
    var offset_sum: Int64 = 0
    var offset_xor: Int64 = 0
    while alignment <= n - m:
        while alignment + matched < n and matched < m and
            input[pattern_start + matched] == input[2 + alignment + matched]:
            matched += 1
        if matched == 0:
            alignment += 1
            suffix_left = -1; suffix_right = 0; suffix_offset = 1; period = 1
            continue
        if matched == m:
            count += 1
            offset_sum += Int64(alignment)
            offset_xor ^= Int64(alignment)
            if alignment == n - m: break

        let base = 2 + alignment
        ordered_alphabets_advance(input, base, matched + 1,
            inout suffix_left, inout suffix_right, inout suffix_offset, inout period)
        let reusable = suffix_left < 0 or
            (suffix_left < period and
             ordered_alphabets_prefix_repeats(input, base, period, suffix_left))
        if reusable:
            alignment += period
            matched -= period
            if matched < 0: matched = 0
            if suffix_right - suffix_left > period: suffix_right -= period
            else: suffix_left = -1; suffix_right = 0; suffix_offset = 1; period = 1
        else:
            let conservative = min(matched - suffix_left - 1, suffix_right + 1)
            let certified = max(suffix_left + 1, conservative)
            alignment += certified + 1
            matched = 0
            suffix_left = -1; suffix_right = 0; suffix_offset = 1; period = 1
    return (count << 36) | (offset_sum << 12) | offset_xor
