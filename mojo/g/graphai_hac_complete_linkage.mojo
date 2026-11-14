# Independent bounded GraphAIBench complete-linkage HAC; see package MIT notice.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("graphai_hac_complete_linkage")
fn graphai_hac_complete_linkage(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 74: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 8 or mv < 0 or mv > 24 or length != c_size_t(2+3*mv): return -1
    let n = Int(nv)
    var matrix = List[Int](capacity=n*n)
    var weights = List[Bool](capacity=33)
    for _ in range(n*n): matrix.append(0)
    for _ in range(33): weights.append(False)
    for e in range(Int(mv)):
        let u = input[2+3*e]
        let v = input[3+3*e]
        let w = input[4+3*e]
        if u < 0 or v <= u or v >= nv or w < 1 or w > 32: return -1
        let a = Int(u)
        let b = Int(v)
        let weight = Int(w)
        if matrix[a*n+b] != 0 or weights[weight]: return -1
        matrix[a*n+b] = weight
        matrix[b*n+a] = weight
        weights[weight] = True
    var reached = 1
    var frontier = 1
    while frontier != 0:
        var next = 0
        for u in range(n):
            if (frontier & (1 << u)) != 0:
                for v in range(n):
                    if matrix[u*n+v] != 0 and (reached & (1 << v)) == 0: next |= 1 << v
        reached |= next
        frontier = next
    if reached != (1 << n)-1: return -1
    let nodes = 2*n-1
    let required = 16*nodes
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    var active = List[Bool](capacity=n)
    var current = List[Int](capacity=n)
    var parent = List[Int64](capacity=nodes)
    var merge_weight = List[Int64](capacity=nodes)
    for u in range(n):
        active.append(True)
        current.append(u)
    for _ in range(nodes):
        parent.append(4294967295)
        merge_weight.append(0)
    for merge in range(n-1):
        var best_u = -1
        var best_v = 0
        var best = 0
        for u in range(n):
            if not active[u]: continue
            for v in range(u+1,n):
                if active[v] and matrix[u*n+v] > best:
                    best = matrix[u*n+v]
                    best_u = u
                    best_v = v
        if best_u < 0: return -1
        let u = best_u
        let v = best_v
        var du = 0
        var dv = 0
        for z in range(n):
            if active[z] and matrix[u*n+z] != 0: du += 1
            if active[z] and matrix[v*n+z] != 0: dv += 1
        var larger = u
        var smaller = v
        if du < dv:
            larger = v
            smaller = u
        let new_id = n+merge
        parent[current[u]] = Int64(new_id)
        parent[current[v]] = Int64(new_id)
        merge_weight[current[u]] = Int64(best)
        merge_weight[current[v]] = Int64(best)
        var combined = List[Int](capacity=n)
        for z in range(n):
            var value = 0
            if active[z] and z != u and z != v:
                let a = matrix[u*n+z]
                let b = matrix[v*n+z]
                if a != 0 and b != 0:
                    value = a
                    if b < value: value = b
                elif a != 0: value = a
                else: value = b
            combined.append(value)
        for z in range(n):
            matrix[u*n+z] = 0
            matrix[z*n+u] = 0
            matrix[v*n+z] = 0
            matrix[z*n+v] = 0
        active[smaller] = False
        for z in range(n):
            if active[z] and z != larger and combined[z] != 0:
                matrix[larger*n+z] = combined[z]
                matrix[z*n+larger] = combined[z]
        current[larger] = new_id
    for node in range(nodes):
        for byte in range(8):
            output[16*node+byte] = UInt8((parent[node] >> (8*byte)) & 255)
            output[16*node+8+byte] = UInt8((merge_weight[node] >> (8*byte)) & 255)
    return Int64(required)
