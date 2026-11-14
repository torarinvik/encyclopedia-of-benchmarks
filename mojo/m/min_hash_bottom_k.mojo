# Supplied-rank bottom-k MinHash with deterministic item-ID ties.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("min_hash_bottom_k")
fn min_hash_bottom_k(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                     output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 35: return -1
    let nv = input[0]
    let kv = input[1]
    if nv < 1 or nv > 16 or kv < 1 or kv > 8 or length != c_size_t(2+2*nv): return -1
    let n = Int(nv)
    let k = Int(kv)
    var ids = List[Int64](capacity=k)
    var ranks = List[Int64](capacity=k)
    var seen = 0
    for i in range(n):
        let id = input[2+2*i]
        let rank = input[3+2*i]
        if id < 0 or id >= 16 or rank < 0 or rank > 1000: return -1
        let bit = 1 << Int(id)
        if (seen & bit) != 0: return -1
        seen |= bit
        var position = 0
        while position < len(ids) and (ranks[position] < rank or (ranks[position] == rank and ids[position] < id)):
            position += 1
        if position < k:
            if len(ids) < k:
                ids.append(0)
                ranks.append(0)
            var j = len(ids)-1
            while j > position:
                ids[j] = ids[j-1]
                ranks[j] = ranks[j-1]
                j -= 1
            ids[position] = id
            ranks[position] = rank
    let count = len(ids)
    let bytes = 8*(1+2*count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for byte in range(8): output[byte] = UInt8((Int64(count) >> (8*byte)) & 255)
    for i in range(count):
        for byte in range(8):
            output[8+16*i+byte] = UInt8((ids[i] >> (8*byte)) & 255)
            output[16+16*i+byte] = UInt8((ranks[i] >> (8*byte)) & 255)
    return Int64(bytes)
