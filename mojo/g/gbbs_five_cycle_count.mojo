# Independent bounded GBBS five-cycle profile; see package MIT notice.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("gbbs_five_cycle_count")
fn gbbs_five_cycle_count(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                         output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 130: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 16 or mv < 0 or mv > 64 or length != c_size_t(2+2*mv): return -1
    let n = Int(nv)
    var rows = List[Int](capacity=n)
    for _ in range(n): rows.append(0)
    for e in range(Int(mv)):
        let u = input[2+2*e]
        let v = input[3+2*e]
        if u < 0 or v <= u or v >= nv: return -1
        let a = Int(u)
        let b = Int(v)
        if (rows[a] & (1 << b)) != 0: return -1
        rows[a] |= 1 << b
        rows[b] |= 1 << a
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    var count = Int64(0)
    for start in range(n):
        for first in range(start+1,n):
            for second in range(start+1,n):
                if second == first: continue
                for third in range(start+1,n):
                    if third == first or third == second: continue
                    for last in range(first+1,n):
                        if last == second or last == third: continue
                        if (rows[start] & (1 << first)) != 0 and (rows[first] & (1 << second)) != 0 and (rows[second] & (1 << third)) != 0 and (rows[third] & (1 << last)) != 0 and (rows[last] & (1 << start)) != 0:
                            count += 1
    for byte in range(8): output[byte] = UInt8((count >> (8*byte)) & 255)
    return 8
