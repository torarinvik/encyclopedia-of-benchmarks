from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("treewidth_min_fill_elimination")
fn treewidth_min_fill_elimination(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 242: return -1
    let n0 = input[0]; let m0 = input[1]
    if n0 < 1 or n0 > 16 or m0 < 0 or m0 > 120: return -1
    let n = Int(n0); let m = Int(m0)
    if m > n * (n - 1) // 2 or length != c_size_t(2 + 2 * m): return -1
    var adjacent = List[Bool](length=n * n, fill=False)
    for edge in range(m):
        let a0 = input[2 + 2 * edge]; let b0 = input[3 + 2 * edge]
        if a0 < 0 or a0 >= b0 or b0 >= n0: return -1
        let a = Int(a0); let b = Int(b0)
        if adjacent[a * n + b]: return -1
        adjacent[a * n + b] = True; adjacent[b * n + a] = True
    var active = List[Bool](length=n, fill=True)
    var order = List[Int]()
    var fills = List[Int]()
    var width = 0
    for _ in range(n):
        var chosen = -1
        var best_fill = 121
        var best_degree = 0
        for vertex in range(n):
            if not active[vertex]: continue
            var neighbors = List[Int]()
            for other in range(n):
                if active[other] and adjacent[vertex * n + other]: neighbors.append(other)
            var missing = 0
            for i in range(len(neighbors)):
                for j in range(i + 1, len(neighbors)):
                    if not adjacent[neighbors[i] * n + neighbors[j]]: missing += 1
            if missing < best_fill:
                chosen = vertex; best_fill = missing; best_degree = len(neighbors)
        order.append(chosen)
        if best_degree > width: width = best_degree
        var neighbors = List[Int]()
        for other in range(n):
            if active[other] and adjacent[chosen * n + other]: neighbors.append(other)
        for i in range(len(neighbors)):
            for j in range(i + 1, len(neighbors)):
                let a = neighbors[i]; let b = neighbors[j]
                if not adjacent[a * n + b]:
                    adjacent[a * n + b] = True; adjacent[b * n + a] = True
                    fills.append(a); fills.append(b)
        active[chosen] = False
    var words = List[Int]()
    words.append(width)
    for vertex in order: words.append(vertex)
    words.append(len(fills) // 2)
    for vertex in fills: words.append(vertex)
    let bytes = 8 * len(words)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for word in range(len(words)):
        for byte in range(8): output[8 * word + byte] = UInt8((words[word] >> (8 * byte)) & 255)
    return Int64(bytes)
