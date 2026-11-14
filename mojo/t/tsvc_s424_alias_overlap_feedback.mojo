from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("tsvc_s424_alias_overlap_feedback")
fn tsvc_s424_alias_overlap_feedback(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 130 or length > 256: return -1
    let n0 = input[0]
    if n0 < 66 or n0 > 192 or length != c_size_t(n0 + 64): return -1
    let n = Int(n0)
    var values = List[Int64]()
    for i in range(n):
        let value = input[1 + i]
        if value < 0 or value > 10: return -1
        values.append(value)
    var backing = List[Int64](length=n + 63, fill=0)
    for i in range(63):
        let value = input[1 + n + i]
        if value < 0 or value > 10: return -1
        backing[i] = value
    for i in range(n - 1): backing[i + 64] = backing[i] + values[i]
    var total = Int64(0)
    for i in range(n): total += backing[63 + i]
    return total
