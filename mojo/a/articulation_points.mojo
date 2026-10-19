from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn articulation_visit(v: Int, n: Int, adjacency: List[UInt64], mut time: Int,
                      mut discovery: List[Int], mut low: List[Int], mut parent: List[Int],
                      mut cut: List[Int]):
    discovery[v] = time
    low[v] = time
    time += 1
    var children = 0
    for neighbor in range(n):
        if (adjacency[v] & (UInt64(1) << UInt(neighbor))) == 0: continue
        if discovery[neighbor] == -1:
            parent[neighbor] = v
            children += 1
            articulation_visit(neighbor, n, adjacency, time, discovery, low, parent, cut)
            if low[neighbor] < low[v]: low[v] = low[neighbor]
            if parent[v] == -1 and children > 1: cut[v] = 1
            if parent[v] != -1 and low[neighbor] >= discovery[v]: cut[v] = 1
        elif neighbor != parent[v] and discovery[neighbor] < low[v]:
            low[v] = discovery[neighbor]

@export("articulation_points")
fn articulation_points(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                       output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 4096 or input[0] < 0 or input[0] > 64 or input[1] < 0 or input[1] > 2047: return -1
    let n = Int(input[0])
    let m = Int(input[1])
    if length != c_size_t(2 + 2 * m): return -1
    var adjacency = List[UInt64](length=64, fill=0)
    for e in range(m):
        let left = input[2 + 2 * e]
        let right = input[3 + 2 * e]
        if left < 0 or left >= Int64(n) or right < 0 or right >= Int64(n): return -1
        adjacency[Int(left)] |= UInt64(1) << UInt(right)
        adjacency[Int(right)] |= UInt64(1) << UInt(left)
    var discovery = List[Int](length=64, fill=-1)
    var low = List[Int](length=64, fill=0)
    var parent = List[Int](length=64, fill=-1)
    var cut = List[Int](length=64, fill=0)
    var time = 0
    for v in range(n):
        if discovery[v] == -1: articulation_visit(v, n, adjacency, time, discovery, low, parent, cut)
    var points = 0
    for v in range(n):
        if cut[v] != 0: points += 1
    if (points > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()) or capacity < c_size_t(points): return -2
    var pos = 0
    for v in range(n):
        if cut[v] != 0:
            output[pos] = UInt8(v)
            pos += 1
    return Int64(points)
