from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("incremental_minimum_spanning_forest")
fn incremental_minimum_spanning_forest(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                       output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 98: return -1
    if input[0] < 1 or input[0] > 16 or input[1] < 1 or input[1] > 32: return -1
    let n = Int(input[0])
    let m = Int(input[1])
    if Int(length) != 2 + 3 * m: return -1
    for i in range(m):
        let u = input[2 + 3 * i]
        let v = input[3 + 3 * i]
        let weight = input[4 + 3 * i]
        if u < 0 or u >= Int64(n) or v < 0 or v >= Int64(n) or weight < 1 or weight > 1000000: return -1
        for j in range(i):
            if input[4 + 3 * j] == weight: return -1
    var active = InlineArray[Bool, 32](fill=False)
    var answers = InlineArray[Int64, 32](fill=0)
    for edge in range(m):
        let start = Int(input[2 + 3 * edge])
        let target = Int(input[3 + 3 * edge])
        if start == target:
            answers[edge] = Int64(edge)
            continue
        var parent = InlineArray[Int, 16](fill=-1)
        var parent_edge = InlineArray[Int, 16](fill=-1)
        var queue = InlineArray[Int, 16](fill=0)
        var head = 0
        var tail = 1
        parent[start] = start
        queue[0] = start
        while head < tail:
            let vertex = queue[head]
            head += 1
            for i in range(edge):
                if not active[i]: continue
                let u = Int(input[2 + 3 * i])
                let v = Int(input[3 + 3 * i])
                var neighbor = -1
                if u == vertex: neighbor = v
                elif v == vertex: neighbor = u
                if neighbor >= 0 and parent[neighbor] < 0:
                    parent[neighbor] = vertex
                    parent_edge[neighbor] = i
                    queue[tail] = neighbor
                    tail += 1
        if parent[target] < 0:
            active[edge] = True
            answers[edge] = -1
            continue
        var node = target
        var heaviest = parent_edge[node]
        while node != start:
            let i = parent_edge[node]
            if input[4 + 3 * i] > input[4 + 3 * heaviest]: heaviest = i
            node = parent[node]
        if input[4 + 3 * edge] < input[4 + 3 * heaviest]:
            active[heaviest] = False
            active[edge] = True
            answers[edge] = Int64(heaviest)
        else: answers[edge] = Int64(edge)
    let bytes = 8 * m
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(m):
        var bits = bitcast[UInt64](answers[i])
        for b in range(8):
            output[8 * i + b] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
