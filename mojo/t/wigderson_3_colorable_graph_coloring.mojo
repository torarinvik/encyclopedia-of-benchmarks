from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_VERTICES = 32
alias MAX_EDGES = 128
alias MAX_INPUT = 2 + 2 * MAX_EDGES

@export("wigderson_3_colorable_graph_coloring")
fn wigderson_3_colorable_graph_coloring(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT + 1:
        return -1
    if input[0] < 0 or input[0] > MAX_VERTICES or input[1] < 0 or input[1] > MAX_EDGES:
        return -1
    let n = Int(input[0])
    let m = Int(input[1])
    if Int(length) != 2 + 2 * m: return -1

    var adjacent = InlineArray[Bool, MAX_VERTICES * MAX_VERTICES](fill=False)
    for edge in range(m):
        let raw_u = input[2 + 2 * edge]
        let raw_v = input[3 + 2 * edge]
        if raw_u < 0 or raw_v <= raw_u or Int(raw_v) >= n: return -1
        let u = Int(raw_u)
        let v = Int(raw_v)
        let uv = u * MAX_VERTICES + v
        let vu = v * MAX_VERTICES + u
        if adjacent[uv]: return -1
        adjacent[uv] = True
        adjacent[vu] = True

    var active = InlineArray[Bool, MAX_VERTICES](fill=False)
    var colors = InlineArray[UInt8, MAX_VERTICES](fill=0)
    for v in range(n): active[v] = True
    var threshold = 0
    while (threshold + 1) * (threshold + 1) <= n: threshold += 1
    var next_color = 1

    while True:
        var chosen = n
        var maximum_degree = 0
        for v in range(n):
            if not active[v]: continue
            var degree = 0
            for w in range(n):
                if active[w] and adjacent[v * MAX_VERTICES + w]: degree += 1
            if chosen == n or degree > maximum_degree:
                chosen = v
                maximum_degree = degree
        if chosen == n or maximum_degree < threshold: break

        var in_neighborhood = InlineArray[Bool, MAX_VERTICES](fill=False)
        var side = InlineArray[Int8, MAX_VERTICES](fill=-1)
        var queue = InlineArray[Int, MAX_VERTICES](fill=0)
        for v in range(n): in_neighborhood[v] = active[v] and adjacent[chosen * MAX_VERTICES + v]
        for root in range(n):
            if not in_neighborhood[root] or side[root] >= 0: continue
            var head = 0
            var tail = 0
            side[root] = 0
            queue[tail] = root
            tail += 1
            while head < tail:
                let u = queue[head]
                head += 1
                for v in range(n):
                    if not in_neighborhood[v] or not adjacent[u * MAX_VERTICES + v]: continue
                    if side[v] < 0:
                        side[v] = 1 - side[u]
                        queue[tail] = v
                        tail += 1
                    elif side[v] == side[u]:
                        return -1
        for v in range(n):
            if in_neighborhood[v]: colors[v] = UInt8(next_color + Int(side[v]))
        colors[chosen] = UInt8(next_color + 2)
        active[chosen] = False
        for v in range(n):
            if adjacent[chosen * MAX_VERTICES + v]: active[v] = False
        next_color += 2

    for v in range(n):
        if not active[v]: continue
        var used = InlineArray[Bool, MAX_VERTICES + 2](fill=False)
        for w in range(n):
            if adjacent[v * MAX_VERTICES + w] and colors[w] > 0:
                used[Int(colors[w])] = True
        var candidate = next_color
        while candidate < MAX_VERTICES + 2 and used[candidate]: candidate += 1
        if candidate >= MAX_VERTICES + 2: return -1
        colors[v] = UInt8(candidate)

    var palette: UInt8 = 0
    for v in range(n):
        if colors[v] > palette: palette = colors[v]
    let output_bytes = n + 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < output_bytes:
        return -2
    output[0] = palette
    for v in range(n): output[v + 1] = colors[v]
    return Int64(output_bytes)
