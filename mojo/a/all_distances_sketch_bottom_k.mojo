from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn put_word(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = bitcast[UInt64](value)
    for j in range(8):
        output[offset+j] = UInt8(bits & UInt64(255))
        bits = bits >> 8

@export("all_distances_sketch_bottom_k")
fn all_distances_sketch_bottom_k(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                 output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > 194: return -1
    let nv = input[0]
    let mv = input[1]
    let kv = input[2]
    let sv = input[3]
    if nv < 2 or nv > 10 or mv < 0 or mv > nv*(nv-1) or kv < 1 or kv > nv or sv < 0 or sv >= nv: return -1
    let n = Int(nv)
    let m = Int(mv)
    let k = Int(kv)
    let source = Int(sv)
    if length != c_size_t(4+n+2*m): return -1
    var ranks = List[Int](capacity=10)
    var seen = List[Bool](capacity=10)
    var distances = List[Int](capacity=10)
    var queue = List[Int](capacity=10)
    var adj = List[Bool](capacity=100)
    for _ in range(10):
        ranks.append(0); seen.append(False); distances.append(-1); queue.append(0)
    for _ in range(100): adj.append(False)
    for i in range(n):
        let rank = input[4+i]
        if rank < 0 or rank >= nv: return -1
        let r = Int(rank)
        if seen[r]: return -1
        seen[r] = True
        ranks[i] = r
    for edge in range(m):
        let uv = input[4+n+2*edge]
        let vv = input[5+n+2*edge]
        if uv < 0 or uv >= nv or vv < 0 or vv >= nv or uv == vv: return -1
        let index = 10*Int(uv)+Int(vv)
        if adj[index]: return -1
        adj[index] = True
    distances[source] = 0
    queue[0] = source
    var head = 0
    var tail = 1
    while head < tail:
        let u = queue[head]
        head += 1
        for v in range(n):
            if adj[10*u+v] and distances[v] < 0:
                distances[v] = distances[u]+1
                queue[tail] = v
                tail += 1
    var words = List[Int64](capacity=21)
    for _ in range(21): words.append(0)
    var count = 0
    for distance in range(n):
        for v in range(n):
            if distances[v] != distance: continue
            var less = 0
            for x in range(n):
                if distances[x] >= 0 and (distances[x] < distance or (distances[x] == distance and x <= v)) and ranks[x] < ranks[v]:
                    less += 1
            if less < k:
                words[1+2*count] = Int64(v)
                words[2+2*count] = Int64(distance)
                count += 1
    words[0] = Int64(count)
    let bytes = 8*(1+2*count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(1+2*count): put_word(output, 8*i, words[i])
    return Int64(bytes)
