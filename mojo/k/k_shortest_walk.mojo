from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("k_shortest_walk")
fn k_shortest_walk(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                   output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 41: return -1
    let n64 = values[0]
    let m64 = values[1]
    let source64 = values[2]
    let target64 = values[3]
    let k64 = values[4]
    if n64 < 1 or n64 > 6 or m64 < 0 or m64 > 12 or k64 < 1 or k64 > 8: return -1
    if source64 < 0 or source64 >= n64 or target64 < 0 or target64 >= n64: return -1
    let n = Int(n64)
    let m = Int(m64)
    let k = Int(k64)
    if length != c_size_t(5 + 3 * m): return -1
    var head = InlineArray[Int, 6](fill=-1)
    var destination = InlineArray[Int, 12](fill=0)
    var weight = InlineArray[Int64, 12](fill=0)
    var next = InlineArray[Int, 12](fill=-1)
    for edge in range(m):
        let u = values[5 + 3 * edge]
        let v = values[6 + 3 * edge]
        let w = values[7 + 3 * edge]
        if u < 0 or u >= n64 or v < 0 or v >= n64 or w < 0 or w > 1000: return -1
        destination[edge] = Int(v)
        weight[edge] = w
        next[edge] = head[Int(u)]
        head[Int(u)] = edge
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * k): return -2
    var distances = InlineArray[Int64, 97](fill=0)
    var vertices = InlineArray[Int, 97](fill=0)
    var expanded = InlineArray[Int, 6](fill=0)
    var answers = InlineArray[Int64, 8](fill=-1)
    vertices[0] = Int(source64)
    var count = 1
    var found = 0
    while count > 0 and found < k:
        let distance = distances[0]
        let vertex = vertices[0]
        for i in range(1, count):
            distances[i - 1] = distances[i]
            vertices[i - 1] = vertices[i]
        count -= 1
        if expanded[vertex] >= k: continue
        expanded[vertex] += 1
        if vertex == Int(target64):
            answers[found] = distance
            found += 1
            if found == k: break
        var edge = head[vertex]
        while edge >= 0:
            let candidate = distance + weight[edge]
            var position = count
            while position > 0 and distances[position - 1] > candidate:
                distances[position] = distances[position - 1]
                vertices[position] = vertices[position - 1]
                position -= 1
            distances[position] = candidate
            vertices[position] = destination[edge]
            count += 1
            edge = next[edge]
    for i in range(k):
        var bits = UInt64(0xffffffffffffffff)
        if answers[i] >= 0: bits = UInt64(answers[i])
        for byte in range(8): output[8 * i + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return Int64(8 * k)
