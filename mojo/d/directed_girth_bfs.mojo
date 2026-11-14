from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("directed_girth_bfs")
fn directed_girth_bfs(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 131: return -1
    if input[0] < 1 or input[0] > 16 or input[1] < 0 or input[1] > 64: return -1
    let n = Int(input[0])
    let m = Int(input[1])
    if length != c_size_t(2+2*m): return -1
    var outgoing = InlineArray[UInt32, 16](fill=0)
    for i in range(m):
        let u = input[2+2*i]
        let v = input[3+2*i]
        if u < 0 or v < 0 or u >= Int64(n) or v >= Int64(n): return -1
        outgoing[Int(u)] |= UInt32(1) << UInt(v)
    var best = 17
    for start in range(n):
        var distance = InlineArray[Int, 16](fill=-1)
        var queue = InlineArray[Int, 16](fill=0)
        distance[start] = 0
        queue[0] = start
        var head = 0
        var tail = 1
        while head < tail:
            let u = queue[head]
            head += 1
            for v in range(n):
                if outgoing[u] & (UInt32(1) << UInt(v)) == 0: continue
                if v == start:
                    if distance[u]+1 < best: best = distance[u]+1
                elif distance[v] < 0:
                    distance[v] = distance[u]+1
                    queue[tail] = v
                    tail += 1
    if best == 17: return 0
    return Int64(best)
