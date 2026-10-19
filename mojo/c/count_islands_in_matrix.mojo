from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("count_islands_in_matrix")
fn count_islands_in_matrix(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or values[0] < 1 or values[0] > 16 or values[1] < 1 or values[1] > 16: return -1
    let rows = values[0]
    let cols = values[1]
    if length != 2 + rows * cols: return -1
    for i in range(rows * cols):
        if values[2 + i] != 0 and values[2 + i] != 1: return -1
    var visited = InlineArray[UInt8, 256](0)
    var queue = InlineArray[Int64, 256](0)
    var components: Int64 = 0
    for index in range(rows * cols):
        if values[2 + index] != 1 or visited[index] != 0: continue
        components += 1
        var head: Int64 = 0
        var tail: Int64 = 1
        queue[0] = index
        visited[index] = 1
        while head < tail:
            let current = queue[head]
            head += 1
            let row = current / cols
            let col = current % cols
            for dr in range(-1, 2):
                for dc in range(-1, 2):
                    if dr == 0 and dc == 0: continue
                    let nr = row + dr
                    let nc = col + dc
                    if nr < 0 or nc < 0 or nr >= rows or nc >= cols: continue
                    let neighbor = nr * cols + nc
                    if values[2 + neighbor] == 1 and visited[neighbor] == 0:
                        visited[neighbor] = 1
                        queue[tail] = neighbor
                        tail += 1
    return components
