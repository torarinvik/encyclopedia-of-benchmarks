from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime AS_MAX_V = 16
comptime AS_MAX_E = 64
comptime AS_MAX_INPUT = 133
comptime AS_MAX_PATHS = 162
comptime AS_MAX_OUTPUT = 1296

fn as_visit(n: Int, target: Int, mut predecessor: InlineArray[UInt8, 256],
            mut useful: InlineArray[UInt8, 16], mut path: InlineArray[UInt8, 16],
            depth: Int, u: Int, mut staged: InlineArray[UInt8, 1296],
            mut used: Int, mut count: Int, mut overflow: Bool):
    if overflow: return
    path[depth] = UInt8(u)
    if u == target:
        if count >= AS_MAX_PATHS or used + depth + 2 > AS_MAX_OUTPUT:
            overflow = True
            return
        for i in range(depth + 1):
            staged[used] = path[i]
            used += 1
        staged[used] = 0xff
        used += 1
        count += 1
        return
    for v in range(n):
        if useful[v] != 0 and predecessor[v * AS_MAX_V + u] != 0:
            as_visit(n, target, mut predecessor, mut useful, mut path, depth + 1, v,
                     mut staged, mut used, mut count, mut overflow)

@export("all_shortest_paths_unweighted")
fn all_shortest_paths_unweighted(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > AS_MAX_INPUT: return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 1 or n_value > AS_MAX_V or m_value < 0 or m_value > AS_MAX_E: return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if input[2] < 0 or input[2] >= n_value or input[3] < 0 or input[3] >= n_value or length != c_size_t(4 + 2 * m): return -1
    let source = Int(input[2])
    let target = Int(input[3])

    var adjacent = InlineArray[UInt8, 256](fill=0)
    for e in range(m):
        let raw_u = input[4 + 2 * e]
        let raw_v = input[5 + 2 * e]
        if raw_u < 0 or raw_u >= n_value or raw_v < 0 or raw_v >= n_value or raw_u == raw_v: return -1
        let u = Int(raw_u)
        let v = Int(raw_v)
        if adjacent[u * AS_MAX_V + v] != 0: return -1
        adjacent[u * AS_MAX_V + v] = 1
        adjacent[v * AS_MAX_V + u] = 1

    var distance = InlineArray[Int, 16](fill= -1)
    var queue = InlineArray[Int, 16](fill=0)
    var predecessor = InlineArray[UInt8, 256](fill=0)
    var head = 0
    var tail = 0
    distance[source] = 0
    queue[tail] = source
    tail += 1
    while head < tail:
        let u = queue[head]
        head += 1
        for v in range(n):
            if adjacent[u * AS_MAX_V + v] == 0: continue
            if distance[v] < 0:
                distance[v] = distance[u] + 1
                queue[tail] = v
                tail += 1
            if distance[v] == distance[u] + 1: predecessor[v * AS_MAX_V + u] = 1

    var useful = InlineArray[UInt8, 16](fill=0)
    if distance[target] >= 0:
        var stack = InlineArray[Int, 16](fill=0)
        var size = 0
        useful[target] = 1
        stack[size] = target
        size += 1
        while size > 0:
            size -= 1
            let v = stack[size]
            for u in range(n):
                if predecessor[v * AS_MAX_V + u] != 0 and useful[u] == 0:
                    useful[u] = 1
                    stack[size] = u
                    size += 1

    var path = InlineArray[UInt8, 16](fill=0)
    var staged = InlineArray[UInt8, 1296](fill=0)
    var used = 0
    var count = 0
    var overflow = False
    if distance[target] >= 0:
        as_visit(n, target, mut predecessor, mut useful, mut path, 0, source,
                 mut staged, mut used, mut count, mut overflow)
    if overflow: return -2
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(used): return -2
    for i in range(used): output[i] = staged[i]
    return Int64(count)
