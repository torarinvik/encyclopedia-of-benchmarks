from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("area_of_island")
fn area_of_island(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or input[0] < 1 or input[0] > 64 or input[1] < 0 or input[1] > 64:
        return -1
    let rows = Int(input[0])
    let columns = Int(input[1])
    let cells = rows * columns
    if length != c_size_t(cells + 2):
        return -1
    var visited = List[Int](length=4096, fill=0)
    var stack = List[Int](length=4096, fill=0)
    var maximum = 0
    for start in range(cells):
        if input[2 + start] == 0 or visited[start] != 0:
            continue
        var top = 0
        var area = 0
        visited[start] = 1
        stack[top] = start
        top += 1
        while top > 0:
            top -= 1
            let current = stack[top]
            area += 1
            let row = current / columns
            let column = current % columns
            if row > 0:
                let neighbor = current - columns
                if visited[neighbor] == 0 and input[2 + neighbor] != 0:
                    visited[neighbor] = 1
                    stack[top] = neighbor
                    top += 1
            if column + 1 < columns:
                let neighbor = current + 1
                if visited[neighbor] == 0 and input[2 + neighbor] != 0:
                    visited[neighbor] = 1
                    stack[top] = neighbor
                    top += 1
            if row + 1 < rows:
                let neighbor = current + columns
                if visited[neighbor] == 0 and input[2 + neighbor] != 0:
                    visited[neighbor] = 1
                    stack[top] = neighbor
                    top += 1
            if column > 0:
                let neighbor = current - 1
                if visited[neighbor] == 0 and input[2 + neighbor] != 0:
                    visited[neighbor] = 1
                    stack[top] = neighbor
                    top += 1
        if area > maximum:
            maximum = area
    return Int64(maximum)
