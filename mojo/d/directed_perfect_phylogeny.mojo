# Independent bounded binary-character compatibility decision; see package attribution.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("directed_perfect_phylogeny")
fn directed_perfect_phylogeny(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                              output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 146: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 12 or mv < 1 or mv > 12 or length != c_size_t(2+nv*mv): return -1
    let n = Int(nv)
    let m = Int(mv)
    var sets = List[Int64](capacity=m)
    for _ in range(m): sets.append(0)
    for row in range(n):
        for col in range(m):
            let value = input[2+row*m+col]
            if value != 0 and value != 1: return -1
            if value == 1: sets[col] |= Int64(1) << row
    var feasible = Int64(1)
    for a in range(m):
        for b in range(a+1, m):
            let overlap = sets[a] & sets[b]
            if overlap != 0 and overlap != sets[a] and overlap != sets[b]: feasible = 0
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    for byte in range(8): output[byte] = UInt8((feasible >> (8*byte)) & 255)
    return 8
