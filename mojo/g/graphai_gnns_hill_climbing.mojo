from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 16
comptime MAX_D = 4
comptime MAX_INPUT = 89
comptime MAX_PARSEABLE = 90
comptime COORD_LIMIT = 100
comptime DISTANCE_RADIX: Int64 = 160_001

@export("graphai_gnns_hill_climbing")
fn graphai_gnns_hill_climbing(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(5) or length > c_size_t(MAX_PARSEABLE):
        return -1
    let n_value = input[0]
    let d_value = input[1]
    let start_value = input[2]
    let e_value = input[3]
    let t_value = input[4]
    if n_value < 2 or n_value > Int64(MAX_N): return -1
    if d_value < 1 or d_value > Int64(MAX_D): return -1
    if start_value < 0 or start_value >= n_value or e_value < 1 or e_value >= n_value:
        return -1
    if t_value < 0 or t_value > 16: return -1
    let n = Int(n_value)
    let d = Int(d_value)
    if length != c_size_t(5 + n * d + n + d) or length > c_size_t(MAX_INPUT): return -1

    var coordinates = InlineArray[Int64, MAX_N * MAX_D](fill=0)
    for index in range(n * d):
        let coordinate = input[5 + index]
        if coordinate < -COORD_LIMIT or coordinate > COORD_LIMIT: return -1
        coordinates[index] = coordinate
    let mask_offset = 5 + n * d
    let allowed: Int64 = (1 << n) - 1
    var masks = InlineArray[Int64, MAX_N](fill=0)
    for vertex in range(n):
        let mask = input[mask_offset + vertex]
        if mask < 0 or mask & ~allowed != 0 or mask & (1 << vertex) != 0: return -1
        masks[vertex] = mask
    var query = InlineArray[Int64, MAX_D](fill=0)
    for axis in range(d):
        let coordinate = input[mask_offset + n + axis]
        if coordinate < -COORD_LIMIT or coordinate > COORD_LIMIT: return -1
        query[axis] = coordinate

    var current = Int(start_value)
    var current_distance: Int64 = 0
    for axis in range(d):
        let delta = coordinates[current * d + axis] - query[axis]
        current_distance += delta * delta
    var evaluations: Int64 = 1
    var moves: Int64 = 0
    for _ in range(Int(t_value)):
        var best_vertex = current
        var best_distance = current_distance
        var inspected: Int64 = 0
        for vertex in range(n):
            if masks[current] & (1 << vertex) == 0: continue
            var distance: Int64 = 0
            for axis in range(d):
                let delta = coordinates[vertex * d + axis] - query[axis]
                distance += delta * delta
            evaluations += 1
            inspected += 1
            if distance < best_distance or (distance == best_distance and vertex < best_vertex):
                best_vertex = vertex
                best_distance = distance
            if inspected == e_value: break
        if best_distance >= current_distance: break
        current = best_vertex
        current_distance = best_distance
        moves += 1
    return (((evaluations * 17 + moves) * 16 + Int64(current)) * DISTANCE_RADIX
            + current_distance)
