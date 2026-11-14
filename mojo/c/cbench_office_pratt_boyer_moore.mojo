# Independently written bounded search profile. Jerry Coffin placed the
# referenced helper in the public domain; see the package's LICENSE.txt.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("cbench_office_pratt_boyer_moore")
fn cbench_office_pratt_boyer_moore(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 321: return -2
    let nv = values[0]
    let mv = values[1]
    if nv < 0 or nv > 255 or mv < 1 or mv > 64: return -2
    let n = Int(nv)
    let m = Int(mv)
    if length != c_size_t(2 + n + m): return -2
    for i in range(n + m):
        if values[2+i] < 1 or values[2+i] > 127: return -2
    let pattern = 2 + n
    var shifts = List[Int](capacity=128)
    for _ in range(128): shifts.append(m)
    for i in range(m): shifts[Int(values[pattern+i])] = m - i - 1
    var endpoint = m - 1
    while endpoint < n:
        let shift = shifts[Int(values[2+endpoint])]
        if shift > 0:
            endpoint += shift
        else:
            let start = endpoint - m + 1
            var matches = True
            for i in range(m):
                if values[2+start+i] != values[pattern+i]:
                    matches = False
                    break
            if matches: return Int64(start)
            endpoint += 1
    return -1
