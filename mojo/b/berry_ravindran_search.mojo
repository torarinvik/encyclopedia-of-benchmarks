from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("berry_ravindran_search")
fn berry_ravindran_search(a: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if a == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 2 or n > 274: return -2
    let tl = a[0]
    let pl = a[1]
    if tl < 0 or tl > 256 or pl < 1 or pl > 16 or n != c_size_t(2 + tl + pl): return -2
    for i in range(Int(tl + pl)):
        if a[i + 2] < 0 or a[i + 2] > 15: return -2
    if pl > tl: return -1
    let text_length = Int(tl)
    let m = Int(pl)
    let p = 2 + text_length
    var shift = InlineArray[Int, 289](fill=m + 2)
    for first in range(17): shift[first * 17 + Int(a[p])] = m + 1
    for i in range(m - 1): shift[Int(a[p + i]) * 17 + Int(a[p + i + 1])] = m - i
    for second in range(17): shift[Int(a[p + m - 1]) * 17 + second] = 1
    var start = 0
    while start + m <= text_length:
        var i = 0
        while i < m and a[2 + start + i] == a[p + i]: i += 1
        if i == m: return start
        let k = start + m
        if k >= text_length: break
        let first = Int(a[2 + k])
        let second = Int(a[2 + k + 1]) if k + 1 < text_length else 16
        start += shift[first * 17 + second]
    return -1
