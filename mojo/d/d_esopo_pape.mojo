from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("d_esopo_pape")
fn d_esopo_pape(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                 output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 195: return -1
    let n64 = values[0]
    let m64 = values[1]
    let source64 = values[2]
    if n64 < 1 or n64 > 16 or m64 < 0 or m64 > 64 or source64 < 0 or source64 >= n64: return -1
    let n = Int(n64)
    let m = Int(m64)
    if length != c_size_t(3 + 3 * m): return -1
    var head = InlineArray[Int, 16](fill=-1)
    var target = InlineArray[Int, 64](fill=0)
    var next = InlineArray[Int, 64](fill=-1)
    var weight = InlineArray[Int64, 64](fill=0)
    for edge in range(m):
        let u = values[3 + 3 * edge]
        let v = values[4 + 3 * edge]
        let w = values[5 + 3 * edge]
        if u < 0 or u >= n64 or v < 0 or v >= n64 or w < 0 or w > 1000: return -1
        target[edge] = Int(v)
        weight[edge] = w
        next[edge] = head[Int(u)]
        head[Int(u)] = edge
    var distance = InlineArray[Int64, 16](fill=0)
    var reachable = InlineArray[Bool, 16](fill=False)
    var queued = InlineArray[Bool, 16](fill=False)
    var removed = InlineArray[Bool, 16](fill=False)
    var queue = InlineArray[Int, 16](fill=0)
    let source = Int(source64)
    queue[0] = source
    reachable[source] = True
    queued[source] = True
    var front = 0
    var size = 1
    while size > 0:
        let vertex = queue[front]
        front = (front + 1) % n
        size -= 1
        queued[vertex] = False
        removed[vertex] = True
        var edge = head[vertex]
        while edge >= 0:
            let neighbor = target[edge]
            let candidate = distance[vertex] + weight[edge]
            if not reachable[neighbor] or candidate < distance[neighbor]:
                reachable[neighbor] = True
                distance[neighbor] = candidate
                if not queued[neighbor]:
                    if removed[neighbor]:
                        front = (front + n - 1) % n
                        queue[front] = neighbor
                    else:
                        queue[(front + size) % n] = neighbor
                    size += 1
                    queued[neighbor] = True
            edge = next[edge]
    let bytes = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for vertex in range(n):
        var bits = UInt64(0xffffffffffffffff)
        if reachable[vertex]: bits = UInt64(distance[vertex])
        for byte in range(8):
            output[8 * vertex + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return Int64(bytes)
