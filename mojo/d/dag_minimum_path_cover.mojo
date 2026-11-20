from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

fn dmpc_augment(left: Int, n: Int, used: UInt32, adjacency: List[UInt32],
                mut seen: List[Bool], mut match_right: List[Int]) -> Bool:
    for right in range(n):
        let bit = UInt32(1) << UInt32(right)
        if adjacency[left] & bit == 0 or used & bit != 0 or seen[right]: continue
        seen[right] = True
        let mate = match_right[right]
        if mate < 0 or dmpc_augment(mate, n, used, adjacency, seen, match_right):
            match_right[right] = left
            return True
    return False

fn dmpc_maximum(n: Int, first: Int, used: UInt32, adjacency: List[UInt32]) -> Int:
    var match_right = List[Int](length=10, fill=-1)
    var size = 0
    for left in range(first, n):
        var seen = List[Bool](length=10, fill=False)
        if dmpc_augment(left, n, used, adjacency, seen, match_right): size += 1
    return size

@export("dag_minimum_path_cover")
fn dag_minimum_path_cover(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 93: return -1
    let n64 = input[0]
    let m64 = input[1]
    if n64 < 1 or n64 > 10 or m64 < 0 or m64 > 45: return -1
    let n = Int(n64)
    let m = Int(m64)
    if length != c_size_t(2 + 2 * m): return -1

    var adjacency = List[UInt32](length=10, fill=0)
    var indegree = List[Int](length=10, fill=0)
    for edge in range(m):
        let u64 = input[2 + 2 * edge]
        let v64 = input[3 + 2 * edge]
        if u64 < 0 or u64 >= n64 or v64 < 0 or v64 >= n64 or u64 == v64: return -1
        let u = Int(u64)
        let v = Int(v64)
        let bit = UInt32(1) << UInt32(v)
        if adjacency[u] & bit != 0: return -1
        adjacency[u] |= bit
        indegree[v] += 1

    var queue = List[Int](capacity=10)
    for vertex in range(n):
        if indegree[vertex] == 0: queue.append(vertex)
    var head = 0
    var removed = 0
    while head < len(queue):
        let u = queue[head]
        head += 1
        removed += 1
        for v in range(n):
            if adjacency[u] & (UInt32(1) << UInt32(v)) != 0:
                indegree[v] -= 1
                if indegree[v] == 0: queue.append(v)
    if removed != n: return -1

    let maximum = dmpc_maximum(n, 0, 0, adjacency)
    var successor = List[Int](length=10, fill=n)
    var used: UInt32 = 0
    var fixed = 0
    for left in range(n):
        var chosen = False
        for right in range(n + 1):
            let matched = right < n
            if matched:
                let bit = UInt32(1) << UInt32(right)
                if adjacency[left] & bit == 0 or used & bit != 0: continue
            let next_used = used | (UInt32(1) << UInt32(right)) if matched else used
            if fixed + (1 if matched else 0) + dmpc_maximum(n, left + 1, next_used, adjacency) == maximum:
                successor[left] = right
                used = next_used
                if matched: fixed += 1
                chosen = True
                break
        if not chosen: return -1

    var packed: UInt64 = UInt64(n - maximum) << 40
    for vertex in range(n):
        packed |= UInt64(successor[vertex]) << UInt64(4 * vertex)
    return Int64(packed)
