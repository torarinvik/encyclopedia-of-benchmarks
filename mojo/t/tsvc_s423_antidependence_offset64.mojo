from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("tsvc_s423_antidependence_offset64")
fn tsvc_s423_antidependence_offset64(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 130 or length > 193: return -1
    let n0 = input[0]
    if n0 < 65 or n0 > 128 or length != c_size_t(n0 + 65): return -1
    let n = Int(n0)
    var values = List[Int64]()
    for i in range(n):
        let value = input[1 + i]
        if value < 0 or value > 2: return -1
        values.append(value)
    var backing = List[Int64](length=n + 64, fill=1)
    for i in range(64):
        let value = input[1 + n + i]
        if value < 0 or value > 2: return -1
        backing[i] = value
    for i in range(n - 1): backing[i + 1] = backing[i + 64] + values[i]
    var total = Int64(0)
    for i in range(n): total += backing[i]
    return total
