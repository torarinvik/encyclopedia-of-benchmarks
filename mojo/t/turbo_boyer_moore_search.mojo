from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("turbo_boyer_moore_search")
fn turbo_boyer_moore_search(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 322:
        return -1
    let text_n = input[0]
    let pattern_n = input[1]
    if text_n < 0 or text_n > 255 or pattern_n < 1 or pattern_n > 64:
        return -1
    let n = Int(text_n)
    let m = Int(pattern_n)
    if length != c_size_t(2 + n + m):
        return -1
    for i in range(n + m):
        if input[2 + i] < 0 or input[2 + i] > 127:
            return -1

    var positions = InlineArray[Int64, 255]()
    var match_count = 0
    if m <= n:
        var bad = InlineArray[Int, 128]()
        var suffix = InlineArray[Int, 64]()
        var good = InlineArray[Int, 64]()
        for byte in range(128):
            bad[byte] = m
        for i in range(m - 1):
            bad[Int(input[2 + n + i])] = m - i - 1

        suffix[m - 1] = m
        var g = m - 1
        var f = 0
        var i = m - 2
        while i >= 0:
            if i > g and suffix[i + m - 1 - f] < i - g:
                suffix[i] = suffix[i + m - 1 - f]
            else:
                if i < g:
                    g = i
                f = i
                while g >= 0 and input[2 + n + g] == input[2 + n + g + m - 1 - f]:
                    g -= 1
                suffix[i] = f - g
            i -= 1
        for j in range(m):
            good[j] = m
        var border = 0
        i = m - 1
        while i >= 0:
            if suffix[i] == i + 1:
                while border < m - 1 - i:
                    if good[border] == m:
                        good[border] = m - 1 - i
                    border += 1
            i -= 1
        for j in range(m - 1):
            good[m - 1 - suffix[j]] = m - 1 - j

        var alignment = 0
        var remembered = 0
        var shift = m
        while alignment <= n - m:
            i = m - 1
            while i >= 0 and input[2 + n + i] == input[2 + alignment + i]:
                i -= 1
                if remembered != 0 and i == m - 1 - shift:
                    i -= remembered
            if i < 0:
                positions[match_count] = Int64(alignment)
                match_count += 1
                shift = good[0]
                remembered = m - shift
            else:
                let matched = m - 1 - i
                let turbo_shift = remembered - matched
                let bad_shift = bad[Int(input[2 + alignment + i])] - m + 1 + i
                let gs = good[i]
                shift = max(turbo_shift, max(bad_shift, gs))
                if shift == gs:
                    remembered = min(m - shift, matched)
                else:
                    if turbo_shift < bad_shift and shift < remembered + 1:
                        shift = remembered + 1
                    remembered = 0
            alignment += shift

    let output_bytes = match_count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(output_bytes):
        return -2
    for i in range(match_count):
        var bits = UInt64(positions[i])
        for byte in range(8):
            output[i * 8 + byte] = UInt8(bits & 255)
            bits >>= 8
    return Int64(output_bytes)
