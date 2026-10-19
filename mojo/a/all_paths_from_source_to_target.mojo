from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn paths_append_i64(mut out: List[UInt8], value: Int64):
    let bits = UInt64(value)
    for b in range(8):
        out.append(UInt8((bits >> (8 * b)) & 255))

fn paths_dfs(vertex: Int, target: Int, vertices: Int, adjacency: List[Int], degrees: List[Int],
             mut visited: List[Bool], mut path: List[Int], mut out: List[UInt8],
             mut count: Int, mut overflow: Bool):
    if overflow:
        return
    if vertex == target:
        if count == 1000:
            overflow = True
            return
        paths_append_i64(out, Int64(len(path)))
        for i in range(len(path)):
            paths_append_i64(out, Int64(path[i]))
        count += 1
        return
    visited[vertex] = True
    for i in range(degrees[vertex]):
        let next = adjacency[vertex * 24 + i]
        if not visited[next] and not overflow:
            path.append(next)
            paths_dfs(next, target, vertices, adjacency, degrees, visited, path, out, count, overflow)
            _ = path.pop()
    visited[vertex] = False

@export("all_paths_from_source_to_target")
fn all_paths_from_source_to_target(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                   output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 52 or input[0] < 1 or input[0] > 8 or input[1] < 0 or input[1] > 24:
        return -1
    let vertices = Int(input[0])
    let edges = Int(input[1])
    if input[2] < 0 or input[2] >= input[0] or input[3] < 0 or input[3] >= input[0] or length != c_size_t(4 + 2 * edges):
        return -1
    let source = Int(input[2])
    let target = Int(input[3])
    var adjacency = List[Int](length=8 * 24, fill=0)
    var degrees = List[Int](length=8, fill=0)
    for e in range(edges):
        let from = input[4 + 2 * e]
        let to = input[5 + 2 * e]
        if from < 0 or from >= input[0] or to < 0 or to >= input[0]:
            return -1
        let u = Int(from)
        adjacency[u * 24 + degrees[u]] = Int(to)
        degrees[u] += 1
    var visited = List[Bool](length=vertices, fill=False)
    var path = List[Int](capacity=vertices)
    path.append(source)
    var encoded = List[UInt8](capacity=72008)
    var count = 0
    var overflow = False
    paths_dfs(source, target, vertices, adjacency, degrees, visited, path, encoded, count, overflow)
    if overflow:
        return -2
    var final = List[UInt8](capacity=8 + len(encoded))
    paths_append_i64(final, Int64(count))
    for i in range(len(encoded)):
        final.append(encoded[i])
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(final)):
        return -2
    for i in range(len(final)):
        output[i] = final[i]
    return Int64(len(final))
