# Independent bounded GAPBS delta-stepping profile; see package BSD notice.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("gapbs_delta_step_sssp")
fn gapbs_delta_step_sssp(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                          output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 196: return -1
    let nv = input[0]
    let mv = input[1]
    let source = input[2]
    let delta = input[3]
    if nv < 1 or nv > 16 or mv < 0 or mv > 64 or source < 0 or source >= nv or delta < 1 or delta > 16 or length != c_size_t(4+3*mv): return -1
    let n = Int(nv)
    let m = Int(mv)
    var from_nodes = List[Int](capacity=m)
    var to_nodes = List[Int](capacity=m)
    var weights = List[Int64](capacity=m)
    for e in range(m):
        let u = input[4+3*e]
        let v = input[5+3*e]
        let w = input[6+3*e]
        if u < 0 or u >= nv or v < 0 or v >= nv or w < 0 or w > 32: return -1
        from_nodes.append(Int(u))
        to_nodes.append(Int(v))
        weights.append(w)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8*n): return -2
    var distance = List[Int64](capacity=n)
    for _ in range(n): distance.append(1073741823)
    distance[Int(source)] = 0
    var heads = List[Int](capacity=481)
    var tails = List[Int](capacity=481)
    for _ in range(481):
        heads.append(-1)
        tails.append(-1)
    var event_vertex = List[Int](capacity=8192)
    var event_next = List[Int](capacity=8192)
    event_vertex.append(Int(source))
    event_next.append(-1)
    heads[0] = 0
    tails[0] = 0
    for bucket in range(481):
        while heads[bucket] >= 0:
            let event = heads[bucket]
            heads[bucket] = event_next[event]
            if heads[bucket] < 0: tails[bucket] = -1
            let u = event_vertex[event]
            if distance[u] < delta*Int64(bucket): continue
            for e in range(m):
                if from_nodes[e] != u: continue
                let v = to_nodes[e]
                let candidate = distance[u]+weights[e]
                if candidate < distance[v]:
                    distance[v] = candidate
                    let target = Int(candidate // delta)
                    if target >= 481 or len(event_vertex) >= 8192: return -1
                    let index = len(event_vertex)
                    event_vertex.append(v)
                    event_next.append(-1)
                    if heads[target] < 0: heads[target] = index
                    else: event_next[tails[target]] = index
                    tails[target] = index
    for u in range(n):
        for byte in range(8): output[8*u+byte] = UInt8((distance[u] >> (8*byte)) & 255)
    return Int64(8*n)
