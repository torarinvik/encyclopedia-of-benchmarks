# SPDX-License-Identifier: GPL-3.0-or-later; see package NOTICE.txt.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("slre")
fn slre(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2: return -2
    let tv = input[0]; let pv = input[1]
    if tv < 0 or tv > 24 or pv < 1 or pv > 24 or length != c_size_t(2+tv+pv): return -2
    let t = Int(tv); let p = Int(pv)
    var text = List[Int](capacity=t)
    var pattern = List[Int](capacity=p)
    for i in range(t):
        let value = input[2+i]
        if value < 97 or value > 122: return -2
        text.append(Int(value))
    for i in range(p): pattern.append(Int(input[2+t+i]))
    var lo = 0; var hi = p
    var anchored_start = False; var anchored_end = False
    if pattern[0] == 94: anchored_start = True; lo += 1
    if lo < hi and pattern[hi-1] == 36: anchored_end = True; hi -= 1
    var i = lo
    var nonempty = False
    while i < hi:
        let c = pattern[i]
        if c == 124:
            if not nonempty: return -2
            nonempty = False; i += 1
            continue
        if not ((c >= 97 and c <= 122) or c == 46): return -2
        nonempty = True; i += 1
        if i < hi and pattern[i] == 63: i += 1
    if not nonempty: return -2
    for start in range(t+1):
        if anchored_start and start > 0: break
        var branch = lo
        while branch <= hi:
            var end = branch
            while end < hi and pattern[end] != 124:
                end += 1
                if end < hi and pattern[end] == 63: end += 1
            var q = branch; var pos = start; var ok = True
            while q < end:
                let c = pattern[q]
                let optional = q+1 < end and pattern[q+1] == 63
                if pos < t and (c == 46 or c == text[pos]): pos += 1
                elif not optional: ok = False; break
                if optional: q += 2
                else: q += 1
            if ok and (not anchored_end or pos == t): return Int64(pos)
            if end == hi: break
            branch = end+1
    return -1
