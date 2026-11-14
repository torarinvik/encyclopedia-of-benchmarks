from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn link_components(u: Int, v: Int, mut component: List[Int]):
    var p1 = component[u]
    var p2 = component[v]
    while p1 != p2:
        let high = max(p1, p2)
        let low = min(p1, p2)
        let parent = component[high]
        if parent == low: break
        if parent == high:
            component[high] = low
            break
        p1 = component[component[high]]
        p2 = component[low]

fn compress_components(n: Int, mut component: List[Int]):
    for vertex in range(n):
        while component[vertex] != component[component[vertex]]:
            component[vertex] = component[component[vertex]]

@export("gapbs_afforest_components")
fn gapbs_afforest_components(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                             output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 195: return -1
    let nv = input[0]
    let mv = input[1]
    let cv = input[2]
    if nv < 1 or nv > 16 or mv < 0 or mv > 64 or cv < 1 or cv > 64: return -1
    let n = Int(nv)
    let m = Int(mv)
    let sample_count = Int(cv)
    if length != c_size_t(3+sample_count+2*m): return -1
    for i in range(sample_count):
        if input[3+i] < 0 or input[3+i] >= nv: return -1
    var adjacency = List[Bool](capacity=256)
    for _ in range(256): adjacency.append(False)
    for edge in range(m):
        let pos = 3+sample_count+2*edge
        let uv = input[pos]
        let vv = input[pos+1]
        if uv < 0 or vv <= uv or vv >= nv: return -1
        let u = Int(uv)
        let v = Int(vv)
        if adjacency[16*u+v]: return -1
        adjacency[16*u+v] = True
        adjacency[16*v+u] = True
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8*n): return -2
    var neighbors = List[Int](capacity=256)
    var degree = List[Int](capacity=16)
    var component = List[Int](capacity=16)
    var counts = List[Int](capacity=16)
    for _ in range(256): neighbors.append(0)
    for i in range(16):
        degree.append(0)
        component.append(i)
        counts.append(0)
    for u in range(n):
        for v in range(n):
            if adjacency[16*u+v]:
                neighbors[16*u+degree[u]] = v
                degree[u] += 1
    for round in range(2):
        for u in range(n):
            if degree[u] > round: link_components(u, neighbors[16*u+round], component)
        compress_components(n, component)
    for i in range(sample_count): counts[component[Int(input[3+i])]] += 1
    var skip_label = 0
    for label in range(1, n):
        if counts[label] > counts[skip_label]: skip_label = label
    var skip_safe = True
    for u in range(n):
        if component[u] == skip_label:
            for offset in range(2, degree[u]):
                if component[neighbors[16*u+offset]] != skip_label: skip_safe = False
    for u in range(n):
        if skip_safe and component[u] == skip_label: continue
        for offset in range(2, degree[u]): link_components(u, neighbors[16*u+offset], component)
    compress_components(n, component)
    for vertex in range(n):
        var bits = UInt64(component[vertex])
        for byte in range(8):
            output[8*vertex+byte] = UInt8(bits & UInt64(255))
            bits = bits >> 8
    return Int64(8*n)
