from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime MAX_TEXT = 4096
comptime MAX_PATTERN = 128
comptime MAX_INPUT = 4227
comptime TABLES = 130

@fieldwise_init
struct GG_Tables:
    var order: InlineArray[Int64, TABLES]
    var next_pos: InlineArray[Int64, TABLES]
    var shift: InlineArray[Int64, TABLES]

fn gg_preprocess(pattern: view[Int64], m: Int, tables: mutable GG_Tables&) -> Int:
    var hmax = InlineArray[Int64, TABLES](fill=0)
    var kmin = InlineArray[Int64, TABLES](fill=0)
    var prefix = InlineArray[Int64, TABLES](fill=0)
    var rmin = InlineArray[Int64, TABLES](fill=0)
    var i = 1
    var k = 1
    while k <= m:
        while pattern[i] == pattern[i-k]: i += 1
        hmax[k] = Int64(i)
        var q = k + 1
        while hmax[q-k] + Int64(k) < Int64(i):
            hmax[q] = hmax[q-k] + Int64(k)
            q += 1
        k = q
        if k == i + 1: i = k
    for x in range(m, 0, -1):
        if hmax[x] < Int64(m): kmin[Int(hmax[x])] = Int64(x)
    var r = m
    for x in range(m-1, -1, -1):
        if hmax[x+1] == Int64(m): r = x+1
        if kmin[x] == 0: rmin[x] = Int64(r)
    var split = -1
    r = m
    for x in range(m):
        if kmin[x] == 0:
            r -= 1
            tables.order[r] = Int64(x)
        else:
            split += 1
            tables.order[split] = Int64(x)
    for x in range(split+1): tables.shift[x] = kmin[Int(tables.order[x])]
    for x in range(split+1, m): tables.shift[x] = rmin[Int(tables.order[x])]
    tables.shift[m] = rmin[0]
    var count = 0
    for x in range(m):
        prefix[x] = Int64(count)
        if kmin[x] > 0: count += 1
    for x in range(split+1):
        let position = Int(tables.order[x])
        tables.next_pos[x] = prefix[Int(tables.order[x] - kmin[position])]
    for x in range(split+1, m):
        tables.next_pos[x] = prefix[m - Int(rmin[Int(tables.order[x])])]
    tables.next_pos[m] = prefix[m - Int(rmin[Int(tables.order[m-1])])]
    return split

fn gg_search(text: view[Int64], pattern: view[Int64], n: Int, m: Int) -> Int64:
    var ell = 0
    while ell + 1 < m and pattern[ell+1] == pattern[0]: ell += 1
    var matches: Int64 = 0
    var offset_sum: Int64 = 0
    var offset_xor: Int64 = 0
    if ell == m - 1:
        var run = 0
        for position in range(n):
            if text[position] == pattern[0]: run += 1 else: run = 0
            if run >= m:
                let start = Int64(position + 1 - m)
                matches += 1
                offset_sum += start
                offset_xor = offset_xor ^ start
        return (matches << 36) | (offset_sum << 12) | offset_xor
    var tables = GG_Tables(
        order=InlineArray[Int64, TABLES](fill=0),
        next_pos=InlineArray[Int64, TABLES](fill=0),
        shift=InlineArray[Int64, TABLES](fill=0),
    )
    let nd = gg_preprocess(pattern,m,tables&)
    if n < m: return 0
    var i = 0
    var j = 0
    var last = -1
    var heavy = False
    while j <= n - m:
        if heavy and i == 0:
            var k = last - j + 1
            while j + k < n and pattern[0] == text[j+k]: k += 1
            if k <= ell or j+k >= n or pattern[ell+1] != text[j+k]:
                i = 0
                j += k + 1
                last = j - 1
            else:
                i = 1
                last = j + k
                j = last - ell - 1
        else:
            while i < m and last < j + Int(tables.order[i]) and
                    pattern[Int(tables.order[i])] == text[j + Int(tables.order[i])]: i += 1
            if i >= m or last >= j + Int(tables.order[i]):
                matches += 1
                offset_sum += Int64(j)
                offset_xor = offset_xor ^ Int64(j)
                i = m
            if i > nd: last = j + m - 1
            j += Int(tables.shift[i])
            i = Int(tables.next_pos[i])
        heavy = j <= last
    (matches << 36) | (offset_sum << 12) | offset_xor

@export("galil_giancarlo_search")
fn galil_giancarlo_search(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT: return -1
    let input_view: view[Int64] = input[0:Int(length)]
    let n_value = input_view[0]
    let m_value = input_view[1]
    if n_value < 0 or n_value > MAX_TEXT or m_value < 1 or m_value > MAX_PATTERN: return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if Int(length) != 2 + n + m: return -1
    var pattern_buffer = InlineArray[Int64, TABLES](fill=0)
    for index in range(m):
        let symbol = input_view[2+n+index]
        if symbol < 0 or symbol > 3: return -1
        pattern_buffer[index] = symbol
    pattern_buffer[m] = 4
    for index in range(n):
        let symbol = input_view[2+index]
        if symbol < 0 or symbol > 3: return -1
    let text_view: view[Int64] = input_view[2:2+n]
    let pattern_view: view[Int64] = pattern_buffer[0:m+1]
    gg_search(text_view,pattern_view,n,m)
