from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn astar_java_f(index: Int, distance: List[Int64], heuristic: List[Int64]) -> Int64:
    return distance[index] + heuristic[index]

fn astar_java_put(output: UnsafePointer[UInt8, MutAnyOrigin], word: Int, value: Int64):
    let bits = UInt64(value)
    for b in range(8): output[word * 8 + b] = UInt8((bits >> UInt(8 * b)) & 255)

@export("astar_java_weighted_graph")
fn astar_java_weighted_graph(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5: return -1
    let n = input[0]
    let m = input[1]
    let start = input[2]
    let target = input[3]
    if n < 1 or n > 7 or m < 0 or m > 16 or start < 0 or start >= n or target < 0 or target >= n or length != c_size_t(4 + n + 3 * m): return -1
    var heuristic = List[Int64](length=7, fill=0)
    for i in range(Int(n)):
        heuristic[i] = input[4 + i]
        if heuristic[i] < -1000 or heuristic[i] > 1000: return -1
    var adj = List[Int](length=49, fill=0)
    var weight = List[Int64](length=49, fill=0)
    var degree = List[Int](length=7, fill=0)
    let edge_start = 4 + Int(n)
    for e in range(Int(m)):
        let u = input[edge_start + 3 * e]
        let v = input[edge_start + 3 * e + 1]
        let w = input[edge_start + 3 * e + 2]
        if u < 0 or u >= n or v < 0 or v >= n or u == v or w < 0 or w > 1000: return -1
        for i in range(degree[Int(u)]):
            if adj[Int(u) * 7 + i] == Int(v): return -1
        adj[Int(u) * 7 + degree[Int(u)]] = Int(v)
        weight[Int(u) * 7 + degree[Int(u)]] = w
        degree[Int(u)] += 1
        adj[Int(v) * 7 + degree[Int(v)]] = Int(u)
        weight[Int(v) * 7 + degree[Int(v)]] = w
        degree[Int(v)] += 1
    var distances = List[Int64](length=4096, fill=0)
    var heuristics = List[Int64](length=4096, fill=0)
    var path_lengths = List[Int](length=4096, fill=0)
    var paths = List[Int64](length=4096 * 7, fill=0)
    distances[0] = 0
    heuristics[0] = heuristic[Int(start)]
    path_lengths[0] = 1
    paths[0] = start
    var heap = List[Int](capacity=4096)
    heap.append(0)
    var state_count = 1
    var solution = -1
    while len(heap) > 0:
        let current_index = heap[0]
        let last = heap[len(heap) - 1]
        heap.pop()
        if len(heap) > 0:
            var i = 0
            let half = len(heap) / 2
            while i < half:
                var child = 2 * i + 1
                var child_index = heap[child]
                if child + 1 < len(heap) and astar_java_f(heap[child + 1], distances, heuristics) < astar_java_f(child_index, distances, heuristics):
                    child += 1
                    child_index = heap[child]
                if astar_java_f(last, distances, heuristics) <= astar_java_f(child_index, distances, heuristics): break
                heap[i] = child_index
                i = child
            heap[i] = last
        let current_vertex = Int(paths[current_index * 7 + path_lengths[current_index] - 1])
        if current_vertex == Int(target):
            solution = current_index
            break
        for edge in range(degree[current_vertex]):
            let next = adj[current_vertex * 7 + edge]
            var in_path = False
            for p in range(path_lengths[current_index]):
                if paths[current_index * 7 + p] == Int64(next): in_path = True
            if in_path: continue
            if state_count >= 4096 or len(heap) >= 4096: return -1
            let child_state = state_count
            state_count += 1
            distances[child_state] = distances[current_index] + weight[current_vertex * 7 + edge]
            heuristics[child_state] = heuristic[next]
            path_lengths[child_state] = path_lengths[current_index] + 1
            for p in range(path_lengths[current_index]): paths[child_state * 7 + p] = paths[current_index * 7 + p]
            paths[child_state * 7 + path_lengths[current_index]] = Int64(next)
            var i = len(heap)
            heap.append(child_state)
            while i > 0:
                let parent_index = (i - 1) / 2
                let parent = heap[parent_index]
                if astar_java_f(parent, distances, heuristics) <= astar_java_f(child_state, distances, heuristics): break
                heap[i] = parent
                i = parent_index
            heap[i] = child_state
    var words = List[Int64](capacity=10)
    if solution < 0:
        words.append(-1)
        words.append(-1)
        words.append(0)
    else:
        words.append(distances[solution])
        words.append(heuristics[solution])
        words.append(Int64(path_lengths[solution]))
        for i in range(path_lengths[solution]): words.append(paths[solution * 7 + i])
    let bytes = len(words) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(words)): astar_java_put(output, i, words[i])
    return Int64(bytes)
