from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("same_value_teleport_bfs")
fn same_value_teleport_bfs(v: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 65:
        return -2
    if v[0] < 1 or v[0] > 64 or length != c_size_t(v[0] + 1):
        return -2
    let n = Int(v[0])
    for i in range(n):
        if v[i + 1] < -64 or v[i + 1] > 64:
            return -2
    if n == 1:
        return 0

    var first = InlineArray[Int32, 129](fill=-1)
    var next = InlineArray[Int32, 64](fill=-1)
    var queue = InlineArray[Int32, 64](fill=0)
    var distance = InlineArray[Int32, 64](fill=-1)
    for i in range(n):
        let slot = Int(v[i + 1] + 64)
        next[i] = first[slot]
        first[slot] = Int32(i)
    var front = 0
    var back = 1
    queue[0] = 0
    distance[0] = 0
    while front < back:
        let index = Int(queue[front])
        front += 1
        if index == n - 1:
            return Int64(distance[index])
        if index > 0 and distance[index - 1] < 0:
            distance[index - 1] = distance[index] + 1
            queue[back] = Int32(index - 1)
            back += 1
        if index + 1 < n and distance[index + 1] < 0:
            distance[index + 1] = distance[index] + 1
            queue[back] = Int32(index + 1)
            back += 1
        let slot = Int(v[index + 1] + 64)
        var member = Int(first[slot])
        if member >= 0:
            first[slot] = -1
            while member >= 0:
                if distance[member] < 0:
                    distance[member] = distance[index] + 1
                    queue[back] = Int32(member)
                    back += 1
                member = Int(next[member])
    return Int64(distance[n - 1])
