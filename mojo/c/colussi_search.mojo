from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("colussi_search")
fn colussi_search(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 4227:
        return -1
    if input[0] < 0 or input[0] > 4096 or input[1] < 1 or input[1] > 128:
        return -1

    let n = Int(input[0])
    let m = Int(input[1])
    if length != c_size_t(2 + n + m):
        return -1
    for index in range(2, Int(length)):
        if input[index] < 0 or input[index] > 3:
            return -1

    var pattern = InlineArray[Int, 129](fill=0)
    let pattern_start = 2 + n
    for index in range(m):
        pattern[index] = Int(input[pattern_start + index])
    pattern[m] = 4

    var hmax = InlineArray[Int, 129](fill=0)
    var kmin = InlineArray[Int, 129](fill=0)
    var nhd0 = InlineArray[Int, 129](fill=0)
    var rmin = InlineArray[Int, 129](fill=0)
    var i = 1
    var k = 1
    while k <= m:
        while pattern[i] == pattern[i - k]:
            i += 1
        hmax[k] = i
        var q = k + 1
        while hmax[q - k] + k < i:
            hmax[q] = hmax[q - k] + k
            q += 1
        k = q
        if k == i + 1:
            i = k

    for index in range(m + 1):
        kmin[index] = 0
    i = m
    while i >= 1:
        if hmax[i] < m:
            kmin[hmax[i]] = i
        i -= 1

    var r = m
    i = m - 1
    while i >= 0:
        if hmax[i + 1] == m:
            r = i + 1
        if kmin[i] == 0:
            rmin[i] = r
        else:
            rmin[i] = 0
        i -= 1

    var h = InlineArray[Int, 129](fill=0)
    var next_positions = InlineArray[Int, 129](fill=0)
    var shift = InlineArray[Int, 129](fill=0)
    var s = -1
    r = m
    for index in range(m):
        if kmin[index] == 0:
            r -= 1
            h[r] = index
        else:
            s += 1
            h[s] = index
    let nd = s

    for index in range(nd + 1):
        shift[index] = kmin[h[index]]
    for index in range(nd + 1, m):
        shift[index] = rmin[h[index]]
    shift[m] = rmin[0]

    s = 0
    for index in range(m):
        nhd0[index] = s
        if kmin[index] > 0:
            s += 1

    for index in range(nd + 1):
        next_positions[index] = nhd0[h[index] - kmin[h[index]]]
    for index in range(nd + 1, m):
        next_positions[index] = nhd0[m - rmin[h[index]]]
    next_positions[m] = nhd0[m - rmin[h[m - 1]]]

    var match_count: Int64 = 0
    var sum_offsets: Int64 = 0
    var xor_offsets: Int64 = 0
    if n >= m:
        i = 0
        var j = 0
        var last = -1
        while j <= n - m:
            while i < m and last < j + h[i] and
                    pattern[h[i]] == Int(input[2 + j + h[i]]):
                i += 1
            var matched = i >= m
            if not matched:
                matched = last >= j + h[i]
            if matched:
                match_count += 1
                sum_offsets += Int64(j)
                xor_offsets ^= Int64(j)
                i = m
            if i > nd:
                last = j + m - 1
            j += shift[i]
            i = next_positions[i]

    return (match_count << 36) | (sum_offsets << 12) | xor_offsets
