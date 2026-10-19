from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn spatial_write(output: UnsafePointer[UInt8, MutAnyOrigin], index: Int, value: Int64):
    let bits = UInt64(value)
    for b in range(8): output[index * 8 + b] = UInt8((bits >> UInt(8 * b)) & 255)

@export("astar_csharp_spatial")
fn astar_csharp_spatial(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4: return -1
    let n = input[0]
    let m = input[1]
    let start = input[2]
    let target = input[3]
    if n < 2 or n > 16 or m != n - 1 or start < 0 or start >= n or target < 0 or target >= n or length != c_size_t(4 + 4 * n + 2 * m): return -1
    let edge_start = 4 + 4 * Int(n)
    var traversable = List[Int](length=16, fill=0)
    var parent = List[Int](length=16, fill=-1)
    for i in range(Int(n)):
        let x = input[4 + 4 * i]
        let y = input[5 + 4 * i]
        let walk = input[6 + 4 * i]
        let multiplier = input[7 + 4 * i]
        if x < -1000 or x > 1000 or y < -1000 or y > 1000 or (walk != 0 and walk != 1) or multiplier < 1 or multiplier > 4: return -1
        for j in range(i):
            if x == input[4 + 4 * j] and y == input[5 + 4 * j]: return -1
        traversable[i] = Int(walk)
    var seen = List[Int](length=16, fill=0)
    var children = List[Int](length=16, fill=0)
    for e in range(Int(m)):
        let from = input[edge_start + 2 * e]
        let to = input[edge_start + 2 * e + 1]
        if from < 0 or from >= n or to < 0 or to >= n or from == to or seen[Int(to)] != 0: return -1
        seen[Int(to)] = 1
        parent[Int(to)] = Int(from)
        children[Int(from)] += 1
        for previous in range(e):
            if input[edge_start + 2 * previous] == from and input[edge_start + 2 * previous + 1] == to: return -1
    if seen[Int(start)] != 0: return -1
    for v in range(Int(n)):
        if v != Int(start) and seen[v] == 0: return -1
    var reached = List[Int](length=16, fill=0)
    var stack = List[Int](capacity=16)
    stack.append(Int(start))
    var visited = 0
    while len(stack) > 0:
        let v = stack.pop()
        if reached[v] != 0: continue
        reached[v] = 1
        visited += 1
        for e in range(Int(m)):
            if input[edge_start + 2 * e] == Int64(v): stack.append(Int(input[edge_start + 2 * e + 1]))
    if visited != Int(n): return -1
    var reverse_path = List[Int64](capacity=16)
    var path_valid = True
    if target != start and traversable[Int(target)] != 0:
        var cursor = Int(target)
        var good = True
        while cursor != Int(start) and cursor >= 0:
            if traversable[cursor] == 0: good = False
            reverse_path.append(Int64(cursor))
            cursor = parent[cursor]
        if cursor != Int(start): good = False
        path_valid = good
    var path_count = len(reverse_path)
    if not path_valid:
        path_count = 0
    let bytes = path_count * 8
    if bytes > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes)): return -2
    for i in range(path_count): spatial_write(output, i, reverse_path[path_count - 1 - i])
    return Int64(bytes)
