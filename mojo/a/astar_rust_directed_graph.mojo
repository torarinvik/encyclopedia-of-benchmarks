from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn astarr_write(output: UnsafePointer[UInt8, MutAnyOrigin], word: Int, value: Int64):
    let bits = UInt64(value)
    for b in range(8): output[word * 8 + b] = UInt8((bits >> UInt(8 * b)) & 255)

@export("astar_rust_directed_graph")
fn astar_rust_directed_graph(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4: return -1
    let n = input[0]
    let m = input[1]
    let start = input[2]
    let goal = input[3]
    if n < 1 or n > 32 or m < 0 or m > 128 or length != c_size_t(4 + n + 3 * m) or start < 0 or start >= n or goal < 0 or goal >= n: return -1
    var heuristic = List[Int64](length=32, fill=0)
    let edge_start = 4 + Int(n)
    for v in range(Int(n)):
        heuristic[v] = input[4 + v]
        if heuristic[v] < 0 or heuristic[v] > 1000000: return -1
    if heuristic[Int(goal)] != 0: return -1
    for e in range(Int(m)):
        let from = input[edge_start + 3 * e]
        let to = input[edge_start + 3 * e + 1]
        let weight = input[edge_start + 3 * e + 2]
        if from < 0 or from >= n or to < 0 or to >= n or weight < 0 or weight > 1000000 or heuristic[Int(from)] > weight + heuristic[Int(to)]: return -1
    var distance = List[Int64](length=32, fill=9223372036854775807)
    var parent = List[Int64](length=32, fill=-1)
    var closed = List[Int](length=32, fill=0)
    distance[Int(start)] = 0
    for _ in range(Int(n)):
        var current = -1
        for v in range(Int(n)):
            if closed[v] != 0 or distance[v] == 9223372036854775807: continue
            if current < 0 or distance[v] + heuristic[v] < distance[current] + heuristic[current] or (distance[v] + heuristic[v] == distance[current] + heuristic[current] and (distance[v] < distance[current] or (distance[v] == distance[current] and v < current))):
                current = v
        if current < 0 or current == Int(goal): break
        closed[current] = 1
        for e in range(Int(m)):
            let pos = edge_start + 3 * e
            if input[pos] != Int64(current): continue
            let next = Int(input[pos + 1])
            let candidate = distance[current] + input[pos + 2]
            if closed[next] == 0 and candidate < distance[next]:
                distance[next] = candidate
                parent[next] = Int64(current)
    if distance[Int(goal)] == 9223372036854775807: return 0
    var reversed = List[Int64](capacity=32)
    var current = goal
    while len(reversed) < Int(n):
        reversed.append(current)
        if current == start: break
        current = parent[Int(current)]
        if current < 0: return -1
    if reversed[len(reversed) - 1] != start: return -1
    let words = len(reversed) + 2
    let bytes = words * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    astarr_write(output, 0, distance[Int(goal)])
    astarr_write(output, 1, Int64(len(reversed)))
    for i in range(len(reversed)):
        astarr_write(output, i + 2, reversed[len(reversed) - 1 - i])
    return Int64(bytes)
