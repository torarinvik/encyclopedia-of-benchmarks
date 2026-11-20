from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_VERTICES = 8
comptime MAX_ARCS = 24
comptime MAX_INPUT_LENGTH = 77
comptime MAX_CAPACITY = Int64(15)

@export("synchronous_round_push_relabel")
fn synchronous_round_push_relabel(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > c_size_t(MAX_INPUT_LENGTH):
        return -1
    let raw_n = input[0]
    let raw_m = input[1]
    let raw_source = input[2]
    let raw_sink = input[3]
    if raw_n < 2 or raw_n > MAX_VERTICES or raw_m < 0 or raw_m > MAX_ARCS or
        raw_source < 0 or raw_source >= raw_n or raw_sink < 0 or raw_sink >= raw_n or
        raw_source == raw_sink:
        return -1
    let n = Int(raw_n)
    let m = Int(raw_m)
    let source = Int(raw_source)
    let sink = Int(raw_sink)
    if length != c_size_t(4 + 3 * m):
        return -1

    var capacity = InlineArray[Int64, 64](fill=0)
    for index in range(m):
        let offset = 4 + 3 * index
        let u = input[offset]
        let v = input[offset + 1]
        let amount = input[offset + 2]
        if u < 0 or u >= raw_n or v < 0 or v >= raw_n or u == v or
            amount < 0 or amount > MAX_CAPACITY:
            return -1
        let cell = Int(u) * MAX_VERTICES + Int(v)
        capacity[cell] += amount

    var residual = capacity
    var excess = InlineArray[Int64, 8](fill=0)
    var height = InlineArray[Int, 8](fill=0)
    height[source] = n
    for vertex in range(n):
        if vertex == source:
            continue
        let forward = source * MAX_VERTICES + vertex
        let reverse = vertex * MAX_VERTICES + source
        let amount = residual[forward]
        if amount != 0:
            residual[forward] = 0
            residual[reverse] += amount
            excess[source] -= amount
            excess[vertex] += amount

    while True:
        var active = InlineArray[Int, 8](fill=0)
        var active_count = 0
        for vertex in range(n):
            if vertex != source and vertex != sink and excess[vertex] > 0 and height[vertex] < n:
                active[active_count] = vertex
                active_count += 1
        if active_count == 0:
            return excess[sink]

        var change = InlineArray[Int64, 8](fill=0)
        for active_index in range(active_count):
            let u = active[active_index]
            var remaining = excess[u]
            for neighbor in range(n):
                if remaining <= 0:
                    break
                let forward = u * MAX_VERTICES + neighbor
                let reverse = neighbor * MAX_VERTICES + u
                if residual[forward] > 0 and height[u] == height[neighbor] + 1:
                    let amount = min(remaining, residual[forward])
                    residual[forward] -= amount
                    residual[reverse] += amount
                    change[u] -= amount
                    change[neighbor] += amount
                    remaining -= amount

        var next_excess = excess
        var next_height = height
        for vertex in range(n):
            next_excess[vertex] += change[vertex]
        for active_index in range(active_count):
            let u = active[active_index]
            if next_excess[u] <= 0:
                continue
            var minimum = 2 * MAX_VERTICES + 1
            for neighbor in range(n):
                if residual[u * MAX_VERTICES + neighbor] > 0 and height[neighbor] < minimum:
                    minimum = height[neighbor]
            next_height[u] = n + 1 if minimum == 2 * MAX_VERTICES + 1 else minimum + 1
        excess = next_excess
        height = next_height
    return -1
