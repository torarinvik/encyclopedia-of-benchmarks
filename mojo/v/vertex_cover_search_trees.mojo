from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn search_cover_bits(mask: Int) -> Int:
    var bits = mask
    var count = 0
    while bits != 0:
        count += bits & 1
        bits >>= 1
    return count

fn search_cover(graph: List[Int], n: Int, active: Int) -> Int:
    var chosen = -1
    var maximum = 0
    for u in range(n):
        if (active & (1 << u)) == 0: continue
        let degree = search_cover_bits(graph[u] & active)
        if degree > maximum:
            maximum = degree
            chosen = u
    if chosen < 0: return 0
    let bit = 1 << chosen
    let first = bit | search_cover(graph,n,active & ~bit)
    let neighbors = graph[chosen] & active
    let second = neighbors | search_cover(graph,n,active & ~(neighbors | bit))
    let first_count = search_cover_bits(first)
    let second_count = search_cover_bits(second)
    if first_count < second_count: return first
    if second_count < first_count: return second
    if first < second: return first
    return second

@export("vertex_cover_search_trees")
fn vertex_cover_search_trees(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 131: return -1
    let nv = input[0]; let mv = input[1]; let k = input[2]
    if nv < 1 or nv > 16 or mv < 0 or mv > 64 or k < 0 or k > nv: return -1
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
    let cover = search_cover(graph,n,(1 << n)-1)
    let count = Int64(search_cover_bits(cover))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 24: return -2
    var decision = Int64(0)
    if count <= k: decision = 1
    for i in range(3):
        var value = decision
        if i == 1: value = count
        elif i == 2: value = Int64(cover)
        for j in range(8): output[8*i+j] = UInt8((value >> (8*j)) & 255)
    return 24
