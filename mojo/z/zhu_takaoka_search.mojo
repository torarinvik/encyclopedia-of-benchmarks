from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("zhu_takaoka_search")
fn zhu_takaoka_search(
    values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 274: return -2
    let raw_n = values[0]
    let raw_m = values[1]
    if raw_n < 0 or raw_n > 256 or raw_m < 2 or raw_m > 16: return -2
    let n = Int(raw_n)
    let m = Int(raw_m)
    if Int(length) != 2 + n + m: return -2
    for i in range(n + m):
        if values[2 + i] < 0 or values[2 + i] >= 16: return -2
    if m > n: return -1

    let p = 2 + n
    var pair_shift = InlineArray[Int, 256](fill=m)
    for a in range(16): pair_shift[a * 16 + Int(values[p])] = m - 1
    for i in range(1, m - 1):
        pair_shift[Int(values[p + i - 1]) * 16 + Int(values[p + i])] = m - 1 - i

    var good_suffix = InlineArray[Int, 16](fill=m)
    for mismatch in range(m):
        for shift in range(1, m + 1):
            let after_mismatch = mismatch + 1
            let first_known = if after_mismatch > shift: after_mismatch else: shift
            var position = first_known
            while position < m and values[p + position] == values[p + position - shift]:
                position += 1
            if position < m: continue
            if mismatch + 1 < m and shift <= mismatch and values[p + mismatch - shift] == values[p + mismatch]: continue
            good_suffix[mismatch] = shift
            break

    var start = 0
    while start <= n - m:
        var mismatch = m
        while mismatch > 0 and values[p + mismatch - 1] == values[2 + start + mismatch - 1]:
            mismatch -= 1
        if mismatch == 0: return Int64(start)
        mismatch -= 1
        let first = Int(values[2 + start + m - 2])
        let second = Int(values[2 + start + m - 1])
        let pair = pair_shift[first * 16 + second]
        start += if good_suffix[mismatch] > pair: good_suffix[mismatch] else: pair
    return -1
