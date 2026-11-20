from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_TEXT = 4096
comptime MAX_PATTERN = 128
comptime MAX_INPUT_LENGTH = 4227

@export("kmp_skip_search")
fn kmp_skip_search(input: UnsafePointer[Int64, ImmutAnyOrigin],
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
        let symbol = input[2 + q]
        if symbol < 0 or symbol > 3:
            return -1
        text[q] = UInt8(symbol)
    for q in range(m):
        let symbol = input[2 + n + q]
        if symbol < 0 or symbol > 3:
            return -1
        pattern[q] = UInt8(symbol)
    if n < m:
        return 0

    var mp_next = InlineArray[Int, MAX_PATTERN + 1](fill=0)
    var kmp_next = InlineArray[Int, MAX_PATTERN + 1](fill=0)
    var q = 0
    var border = -1
    mp_next[0] = -1
    while q < m:
        while border >= 0 and pattern[q] != pattern[border]:
            border = mp_next[border]
        q += 1
        border += 1
        mp_next[q] = border
    q = 0
    border = -1
    kmp_next[0] = -1
    while q < m:
        while border >= 0 and pattern[q] != pattern[border]:
            border = kmp_next[border]
        q += 1
        border += 1
        if q < m and pattern[q] == pattern[border]:
            kmp_next[q] = kmp_next[border]
        else:
            kmp_next[q] = border

    var last = InlineArray[Int, 4](fill=-1)
    var previous = InlineArray[Int, MAX_PATTERN](fill=-1)
    for q in range(m):
        let symbol = Int(pattern[q])
        previous[q] = last[symbol]
        last[symbol] = q

    var sample = -1
    var i = -1
    while true:
        sample += m
        if sample >= n:
            return 0
        i = last[Int(text[sample])]
        if i >= 0:
            break
    var start = sample - i
    var wall = 0
    let period = m - kmp_next[m]
    var count: Int64 = 0
    var offset_sum: Int64 = 0
    var offset_xor: Int64 = 0
    while start <= n - m:
        if start > wall:
            wall = start
        var k = wall - start
        while k < m and pattern[k] == text[start + k]:
            k += 1
        wall = start + k
        if k == m:
            count += 1
            offset_sum += Int64(start)
            offset_xor ^= Int64(start)
            i -= period
        else:
            i = previous[i]
        if i < 0:
            var found = False
            while true:
                sample += m
                if sample >= n:
                    break
                i = last[Int(text[sample])]
                if i >= 0:
                    found = True
                    break
            if not found:
                break

        var kmp_start = start + k - kmp_next[k]
        k = kmp_next[k]
        start = sample - i
        while start < kmp_start or (kmp_start < start and start < wall):
            if start < kmp_start:
                i = previous[i]
                if i < 0:
                    var found = False
                    while true:
                        sample += m
                        if sample >= n:
                            break
                        i = last[Int(text[sample])]
                        if i >= 0:
                            found = True
                            break
                    if not found:
                        return (count << 36) | (offset_sum << 12) | offset_xor
                start = sample - i
            else:
                kmp_start += k - mp_next[k]
                k = mp_next[k]

    return (count << 36) | (offset_sum << 12) | offset_xor
