from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("connected_components")
fn connected_components(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or input[0] < 0 or input[0] > 256 or input[1] < 0 or input[1] > 512: return -1
    let n = input[0]
    let m = input[1]
    if length != 2 + 2 * m: return -1
    var adjacency = InlineArray[UInt8, 65536](0)
    for e in range(m):
        let u = input[2 + 2 * e]
        let v = input[3 + 2 * e]
        if u < 1 or u > n or v < 1 or v > n: return -1
        adjacency[(u - 1) * 256 + (v - 1)] = 1
        adjacency[(v - 1) * 256 + (u - 1)] = 1
    var seen = InlineArray[UInt8, 256](0)
    var components: Int64 = 0
    for start in range(n):
        if seen[start] != 0: continue
        components += 1
        seen[start] = 1
        var queue = InlineArray[Int64, 256](0)
        queue[0] = start
        var head: Int64 = 0
        var tail: Int64 = 1
        while head < tail:
            let vertex = queue[head]
            head += 1
            for next in range(n):
                if adjacency[vertex * 256 + next] != 0 and seen[next] == 0:
                    seen[next] = 1
                    queue[tail] = next
                    tail += 1
    return components
