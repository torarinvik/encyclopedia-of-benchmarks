from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn reachability_rebuild(n: Int, source: Int, adjacency: List[Bool],
        mut reachable: List[Bool]):
    for v in range(n): reachable[v] = False
    var queue = List[Int]()
    reachable[source] = True
    queue.append(source)
    var head = 0
    while head < len(queue):
        let u = queue[head]
        head += 1
        for v in range(n):
            if adjacency[u * n + v] and not reachable[v]:
                reachable[v] = True
                queue.append(v)

@export("single_source_dynamic_reachability_rebuild")
fn single_source_dynamic_reachability_rebuild(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
        capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 97: return -1
    let n0 = input[0]; let source0 = input[1]; let edges0 = input[2]
    if n0 < 2 or n0 > 8 or source0 < 0 or source0 >= n0 or edges0 < 0 or edges0 > 16: return -1
    let n = Int(n0); let source = Int(source0); let edges = Int(edges0)
    let op_at = 3 + 2 * edges
    if length <= c_size_t(op_at): return -1
    let operations0 = input[op_at]
    if operations0 < 0 or operations0 > 20 or length != c_size_t(op_at + 1 + 3 * Int(operations0)): return -1
    let operations = Int(operations0)
    var adjacency = List[Bool](length=n * n, fill=False)
    for edge in range(edges):
        let u = input[3 + 2 * edge]; let v = input[4 + 2 * edge]
        if u < 0 or u >= n0 or v < 0 or v >= n0: return -1
        let slot = Int(u) * n + Int(v)
        if adjacency[slot]: return -1
        adjacency[slot] = True
    var query_count = 0
    for op in range(operations):
        let pos = op_at + 1 + 3 * op
        let kind = input[pos]; let u = input[pos + 1]; let v = input[pos + 2]
        if u < 0 or u >= n0: return -1
        if kind == 0 or kind == 1:
            if v < 0 or v >= n0: return -1
        elif kind == 2:
            if v != 0: return -1
            query_count += 1
        else: return -1
    let bytes = 8 * (1 + query_count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var reachable = List[Bool](length=n, fill=False)
    var answers = List[Int64]()
    reachability_rebuild(n, source, adjacency, reachable)
    for op in range(operations):
        let pos = op_at + 1 + 3 * op
        let kind = input[pos]; let u = Int(input[pos + 1]); let v = Int(input[pos + 2])
        if kind == 0 or kind == 1:
            adjacency[u * n + v] = kind == 0
            reachability_rebuild(n, source, adjacency, reachable)
        else:
            var answer = Int64(0)
            if reachable[u]: answer = 1
            answers.append(answer)
    for word in range(query_count + 1):
        var value = Int64(query_count)
        if word > 0: value = answers[word - 1]
        for byte in range(8): output[8 * word + byte] = UInt8((value >> (8 * byte)) & 255)
    return Int64(bytes)
