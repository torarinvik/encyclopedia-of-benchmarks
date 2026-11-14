# Independent supplied rank assignments for k-mins MinHash.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("min_hash_k_mins")
fn min_hash_k_mins(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                   output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 66: return -1
    let nv = input[0]
    let kv = input[1]
    if nv < 1 or nv > 16 or kv < 1 or kv > 4 or length != c_size_t(2+nv*kv): return -1
    let n = Int(nv)
    let k = Int(kv)
    var best_ids = List[Int64](capacity=k)
    var best_ranks = List[Int64](capacity=k)
    for _ in range(k):
        best_ids.append(0)
        best_ranks.append(1001)
    for row in range(n):
        for column in range(k):
            let rank = input[2+row*k+column]
            if rank < 0 or rank > 1000: return -1
            if rank < best_ranks[column]:
                best_ranks[column] = rank
                best_ids[column] = Int64(row)
    let bytes = 8*k
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(k):
        for byte in range(8): output[8*i+byte] = UInt8((best_ids[i] >> (8*byte)) & 255)
    return Int64(bytes)
