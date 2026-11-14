# Weighted list ranking by deterministic independent-set contraction.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("list_ranking_independent_set_contraction")
fn list_ranking_independent_set_contraction(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                            output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 34: return -1
    let nv = input[0]
    let head = input[1]
    if nv < 1 or nv > 16 or head < 0 or head >= nv or length != c_size_t(2 + 2*nv): return -1
    let n = Int(nv)
    var weights = List[Int64](capacity=n)
    var successors = List[Int](capacity=n)
    var indegree = List[Int](capacity=n)
    var seen = List[Bool](capacity=n)
    var rank = List[Int64](capacity=n)
    for _ in range(n):
        indegree.append(0)
        seen.append(False)
        rank.append(0)
    var tails = 0
    for i in range(n):
        let weight = input[2+i]
        let successor = input[2+n+i]
        if weight < 1 or weight > 10000 or successor < -1 or successor >= nv: return -1
        weights.append(weight)
        successors.append(Int(successor))
        if successor == -1:
            tails += 1
        else:
            let next = Int(successor)
            indegree[next] += 1
            if indegree[next] > 1: return -1
    if tails != 1 or indegree[Int(head)] != 0: return -1
    var path = List[Int](capacity=n)
    var node = Int(head)
    while node != -1:
        if seen[node] or len(path) == n: return -1
        seen[node] = True
        path.append(node)
        node = successors[node]
    if len(path) != n: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8*n): return -2

    var removed = List[Int](capacity=n)
    var following = List[Int](capacity=n)
    var saved_weight = List[Int64](capacity=n)
    while len(path) > 1:
        var counts = List[Int](capacity=3)
        for _ in range(3): counts.append(0)
        for position in range(len(path)-1): counts[position % 3] += 1
        var color = 0
        for candidate in range(1, 3):
            if counts[candidate] > counts[color]: color = candidate
        var next_path = List[Int](capacity=n)
        for position in range(len(path)):
            let current = path[position]
            if position + 1 < len(path) and position % 3 == color:
                let next = path[position+1]
                removed.append(current)
                following.append(next)
                saved_weight.append(weights[next])
                weights[next] += weights[current]
            else:
                next_path.append(current)
        path = next_path^
    rank[path[0]] = weights[path[0]]
    var remaining = len(removed)
    while remaining > 0:
        remaining -= 1
        rank[removed[remaining]] = rank[following[remaining]] - saved_weight[remaining]
    for i in range(n):
        for byte in range(8): output[8*i+byte] = UInt8((rank[i] >> (8*byte)) & 255)
    return Int64(8*n)
