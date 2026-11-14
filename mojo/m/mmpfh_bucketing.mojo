# Equal-size bucket delimiters for bounded monotone perfect hashing.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("mmpfh_bucketing")
fn mmpfh_bucketing(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                   output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 66: return -1
    let nv = input[0]
    let qv = input[1]
    if nv < 1 or nv > 32 or qv < 1 or qv > 32 or length != c_size_t(2+nv+qv): return -1
    let n = Int(nv)
    let q = Int(qv)
    var keys = List[Int](capacity=n)
    var query_positions = List[Int](capacity=q)
    for i in range(n):
        let key = input[2+i]
        if key < 0 or key > 65535 or (i > 0 and key <= Int64(keys[i-1])): return -1
        keys.append(Int(key))
    for i in range(q):
        let query = input[2+n+i]
        if query < 0 or query > 65535: return -1
        var position = -1
        for j in range(n):
            if keys[j] == Int(query):
                position = j
                break
        if position < 0: return -1
        query_positions.append(position)
    let buckets = (n+2) // 3
    var lengths = List[Int](capacity=buckets)
    var prefixes = List[Int](capacity=buckets)
    for b in range(buckets):
        let start = 3*b
        var end = start+3
        if end > n: end = n
        let difference = keys[start] ^ keys[end-1]
        var prefix_length = 0
        while prefix_length < 16 and (difference & (1 << (15-prefix_length))) == 0:
            prefix_length += 1
        lengths.append(prefix_length)
        prefixes.append(keys[start] >> (16-prefix_length))
    var fields = List[Int64](capacity=100)
    fields.append(nv); fields.append(Int64(buckets)); fields.append(qv)
    for i in range(n): fields.append(Int64(lengths[i // 3]))
    for b in range(buckets):
        fields.append(Int64(lengths[b])); fields.append(Int64(prefixes[b])); fields.append(Int64(b))
    for position in query_positions:
        let prefix_length = lengths[position // 3]
        let prefix = keys[position] >> (16-prefix_length)
        var bucket = 0
        while bucket < buckets and (lengths[bucket] != prefix_length or prefixes[bucket] != prefix): bucket += 1
        if bucket == buckets: return -1
        fields.append(Int64(position))
    let bytes = 8*len(fields)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(fields)):
        for byte in range(8): output[8*i+byte] = UInt8((fields[i] >> (8*byte)) & 255)
    return Int64(bytes)
