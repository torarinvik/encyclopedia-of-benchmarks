from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("negative_cycle_detection")
fn negative_cycle_detection(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 194: return -1
    let n64 = input[0]
    let m64 = input[1]
    if n64 < 0 or n64 > 20 or m64 < 0 or m64 > 64 or length != c_size_t(2 + 3 * m64): return -1
    let n = Int(n64)
    let m = Int(m64)
    for edge in range(m):
        let u = input[2 + 3 * edge]
        let v = input[3 + 3 * edge]
        let w = input[4 + 3 * edge]
        if u < 0 or u >= n64 or v < 0 or v >= n64 or w < -1000 or w > 1000: return -1
    var distance = InlineArray[Int64, 20](fill=0)
    var predecessor = InlineArray[Int, 20](fill=-1)
    var changed = -1
    for _ in range(n):
        changed = -1
        for edge in range(m):
            let u = Int(input[2 + 3 * edge])
            let v = Int(input[3 + 3 * edge])
            let candidate = distance[u] + input[4 + 3 * edge]
            if candidate < distance[v]:
                distance[v] = candidate
                predecessor[v] = u
                changed = v
        if changed < 0: break
    var record = InlineArray[Int64, 22](fill=0)
    var count = 1
    if changed >= 0:
        var vertex = changed
        for _ in range(n):
            if predecessor[vertex] < 0: return -1
            vertex = predecessor[vertex]
        let start = vertex
        var cycle = InlineArray[Int, 20](fill=0)
        var cycle_length = 0
        while True:
            if cycle_length >= n or predecessor[vertex] < 0: return -1
            cycle[cycle_length] = vertex
            cycle_length += 1
            vertex = predecessor[vertex]
            if vertex == start: break
        var minimum = 0
        for i in range(1, cycle_length):
            if cycle[cycle_length - 1 - i] < cycle[cycle_length - 1 - minimum]: minimum = i
        record[0] = 1
        record[1] = Int64(cycle_length)
        for i in range(cycle_length):
            let index = (minimum + i) % cycle_length
            record[2 + i] = Int64(cycle[cycle_length - 1 - index])
        count = cycle_length + 2
    let bytes = 8 * count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(count):
        let bits = UInt64(record[i])
        for byte in range(8): output[8 * i + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return Int64(bytes)
