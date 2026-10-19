from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("close_strings")
fn close_strings(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 514: return -1
    let n1 = values[0]
    let n2 = values[1]
    if n1 < 0 or n1 > 256 or n2 < 0 or n2 > 256 or length != 2 + n1 + n2: return -1
    var first = InlineArray[Int64, 26](0)
    var second = InlineArray[Int64, 26](0)
    for i in range(n1):
        let ch = values[2 + i]
        if ch < 97 or ch > 122: return -1
        first[ch - 97] += 1
    for i in range(n2):
        let ch = values[2 + n1 + i]
        if ch < 97 or ch > 122: return -1
        second[ch - 97] += 1
    if n1 != n2: return 0
    var freq1 = InlineArray[Int64, 257](0)
    var freq2 = InlineArray[Int64, 257](0)
    for i in range(26):
        if (first[i] == 0) != (second[i] == 0): return 0
        freq1[first[i]] += 1
        freq2[second[i]] += 1
    for i in range(257):
        if freq1[i] != freq2[i]: return 0
    return 1
