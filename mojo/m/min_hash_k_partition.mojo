# Supplied-tape k-partition MinHash sketch.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("min_hash_k_partition")
fn min_hash_k_partition(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 66: return -1
    let kv = input[0]
    let nv = input[1]
    if kv < 1 or kv > 8 or nv < 0 or nv > 32 or length != c_size_t(2+2*nv): return -1
    let k = Int(kv)
    let n = Int(nv)
    var ids = List[Int64](capacity=k)
    var ranks = List[Int64](capacity=k)
    for _ in range(k):
        ids.append(-1)
        ranks.append(1001)
    for id in range(n):
        let bucket = input[2+2*id]
        let rank = input[3+2*id]
        if bucket < 0 or bucket >= kv or rank < 0 or rank > 1000: return -1
        let b = Int(bucket)
        if rank < ranks[b]:
            ids[b] = Int64(id)
            ranks[b] = rank
    let bytes = 16*k
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for b in range(k):
        for byte in range(8):
            output[16*b+byte] = UInt8((ids[b] >> (8*byte)) & 255)
            output[16*b+8+byte] = UInt8((ranks[b] >> (8*byte)) & 255)
    return Int64(bytes)
