# Independent bounded cardinality-constrained first fit; see package attribution.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("first_fit_cardinality_bin_packing")
fn first_fit_cardinality_bin_packing(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                     output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 35: return -1
    let nv = input[0]
    let limit = input[1]
    let cap = input[2]
    if nv < 1 or nv > 32 or limit < 1 or limit > 32 or cap < 1 or cap > 10000 or length != c_size_t(3+nv): return -1
    let n = Int(nv)
    for i in range(n):
        if input[3+i] < 1 or input[3+i] > cap: return -1
    var loads = List[Int64](capacity=n)
    var counts = List[Int64](capacity=n)
    var owners = List[Int64](capacity=n)
    for i in range(n):
        let size = input[3+i]
        var b = 0
        while b < len(loads) and (counts[b] >= limit or loads[b] > cap-size): b += 1
        if b == len(loads):
            loads.append(0)
            counts.append(0)
        loads[b] += size
        counts[b] += 1
        owners.append(Int64(b))
    let required = 8*(n+1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    let bins = Int64(len(loads))
    for byte in range(8): output[byte] = UInt8((bins >> (8*byte)) & 255)
    for i in range(n):
        for byte in range(8): output[8*(i+1)+byte] = UInt8((owners[i] >> (8*byte)) & 255)
    return Int64(required)
