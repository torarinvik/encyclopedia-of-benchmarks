from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("check_cycle")
fn check_cycle(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or input[0] < 0 or input[0] > 32 or input[1] < 0 or input[1] > 256: return -1
    let vertices = input[0]
    let edges = input[1]
    if length != 2 + 2 * edges: return -1
    var adjacency = InlineArray[UInt8, 1024](0)
    for edge in range(edges):
        let origin = input[2 + 2 * edge]
        let destination = input[3 + 2 * edge]
        if origin < 0 or origin >= vertices or destination < 0 or destination >= vertices: return -1
        adjacency[origin * 32 + destination] = 1
    var color = InlineArray[UInt8, 32](0)
    var stack = InlineArray[Int64, 32](0)
    var next_neighbor = InlineArray[Int64, 32](0)
    for start in range(vertices):
        if color[start] != 0: continue
        var top: Int64 = 1
        stack[0] = start
        next_neighbor[0] = 0
        color[start] = 1
        while top != 0:
            let frame = top - 1
            let current = stack[frame]
            while next_neighbor[frame] < vertices and adjacency[current * 32 + next_neighbor[frame]] == 0:
                next_neighbor[frame] += 1
            if next_neighbor[frame] == vertices:
                color[current] = 2
                top -= 1
                continue
            let neighbor = next_neighbor[frame]
            next_neighbor[frame] += 1
            if color[neighbor] == 1: return 1
            if color[neighbor] == 0:
                color[neighbor] = 1
                stack[top] = neighbor
                next_neighbor[top] = 0
                top += 1
    return 0
