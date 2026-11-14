from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn cover_degree(mask: Int) -> Int:
    var bits = mask
    var count = 0
    while bits != 0:
        count += bits & 1
        bits >>= 1
    return count

@export("vertex_cover_kernelization")
fn vertex_cover_kernelization(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 131: return -1
    let nv = input[0]; let mv = input[1]; let kv = input[2]
    if nv < 1 or nv > 16 or mv < 0 or mv > 64 or kv < 0 or kv > 16: return -1
    if length != c_size_t(3+2*Int(mv)): return -1
    let n = Int(nv)
    var graph = List[Int](capacity=n)
    for _ in range(n): graph.append(0)
    var previous_u = Int64(-1)
    var previous_v = Int64(-1)
    for i in range(Int(mv)):
        let u = input[3+2*i]; let v = input[4+2*i]
        if u < 0 or v <= u or v >= nv or u < previous_u or (u == previous_u and v <= previous_v): return -1
        graph[Int(u)] |= 1 << Int(v)
        graph[Int(v)] |= 1 << Int(u)
        previous_u = u; previous_v = v
    var active = (1 << n)-1
    var forced = 0
    var remaining = Int(kv)
    while remaining >= 0:
        var isolated = -1
        for u in range(n):
            if (active & (1 << u)) != 0 and graph[u] == 0:
                isolated = u
                break
        if isolated >= 0:
            active &= ~(1 << isolated)
            continue
        var chosen = -1
        for u in range(n):
            if (active & (1 << u)) != 0 and cover_degree(graph[u]) == 1:
                for v in range(n):
                    if (graph[u] & (1 << v)) != 0:
                        chosen = v
                        break
                break
        if chosen < 0:
            for u in range(n):
                if (active & (1 << u)) != 0 and cover_degree(graph[u]) > remaining:
                    chosen = u
                    break
        if chosen < 0: break
        forced |= 1 << chosen
        active &= ~(1 << chosen)
        remaining -= 1
        for v in range(n): graph[v] &= ~(1 << chosen)
        graph[chosen] = 0
    var fields = List[Int64](capacity=133)
    var status = Int64(1)
    if remaining < 0: status = 0
    fields.append(status); fields.append(Int64(remaining)); fields.append(Int64(forced)); fields.append(Int64(active)); fields.append(0)
    var edges = 0
    for u in range(n):
        for v in range(u+1,n):
            if (graph[u] & (1 << v)) != 0:
                fields.append(Int64(u)); fields.append(Int64(v)); edges += 1
    fields[4] = Int64(edges)
    let bytes = 8*len(fields)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(fields)):
        for j in range(8): output[8*i+j] = UInt8((fields[i] >> (8*j)) & 255)
    return Int64(bytes)
