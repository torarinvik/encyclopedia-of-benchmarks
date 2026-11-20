from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn mg_free(vertex: Int, color: Int64, vertices: Int,
           edge_at: InlineArray[Int32, 36],
           colors: InlineArray[Int64, 6]) -> Bool:
    for other in range(vertices):
        let edge = Int(edge_at[vertex * 6 + other])
        if edge >= 0 and colors[edge] == color:
            return False
    return True

@export("misra_gries_edge_coloring")
fn misra_gries_edge_coloring(input: UnsafePointer[Int64, ImmutAnyOrigin],
                             length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 15:
        return -1
    if input[0] < 1 or input[0] > 6 or input[1] < 0 or input[1] > 6:
        return -1
    let vertices = Int(input[0])
    let edge_count = Int(input[1])
    if length != c_size_t(2 + 2 * edge_count):
        return -1
    var left = InlineArray[Int32, 6]()
    var right = InlineArray[Int32, 6]()
    var degree = InlineArray[Int32, 6]()
    var edge_at = InlineArray[Int32, 36](fill=-1)
    for edge in range(edge_count):
        let a = input[2 + 2 * edge]
        let b = input[3 + 2 * edge]
        if a < 0 or b < 0 or a >= vertices or b >= vertices or a == b:
            return -1
        let u = Int(a if a < b else b)
        let v = Int(b if a < b else a)
        if edge_at[u * 6 + v] >= 0:
            return -1
        left[edge] = Int32(u)
        right[edge] = Int32(v)
        edge_at[u * 6 + v] = Int32(edge)
        edge_at[v * 6 + u] = Int32(edge)
        degree[u] += 1
        degree[v] += 1
    var delta = 0
    for vertex in range(vertices):
        if Int(degree[vertex]) > delta:
            delta = Int(degree[vertex])
    let palette = 0 if edge_count == 0 else delta + 1
    var colors = InlineArray[Int64, 6](fill=-1)

    for edge in range(edge_count):
        let center = Int(left[edge])
        var fan = InlineArray[Int32, 6]()
        var fan_count = 1
        fan[0] = right[edge]
        while True:
            let tail = Int(fan[fan_count - 1])
            var extended = False
            for neighbor in range(vertices):
                let candidate = Int(edge_at[center * 6 + neighbor])
                if candidate < 0 or colors[candidate] < 0:
                    continue
                var present = False
                for i in range(fan_count):
                    if Int(fan[i]) == neighbor:
                        present = True
                if present or not mg_free(tail, colors[candidate], vertices, edge_at, colors):
                    continue
                fan[fan_count] = Int32(neighbor)
                fan_count += 1
                extended = True
                break
            if not extended:
                break
        var color_c: Int64 = 0
        while color_c < palette and not mg_free(center, color_c, vertices, edge_at, colors):
            color_c += 1
        var color_d: Int64 = 0
        while color_d < palette and not mg_free(Int(fan[fan_count - 1]), color_d, vertices, edge_at, colors):
            color_d += 1
        if color_c >= palette or color_d >= palette:
            return -1

        var path = InlineArray[Int32, 6]()
        var path_count = 0
        var current = center
        var wanted = color_d
        var visited = InlineArray[Bool, 6](fill=False)
        visited[current] = True
        for step in range(vertices):
            var path_edge = -1
            var next = 0
            for neighbor in range(vertices):
                let candidate = Int(edge_at[current * 6 + neighbor])
                if candidate >= 0 and colors[candidate] == wanted:
                    path_edge = candidate
                    next = neighbor
                    break
            if path_edge < 0 or visited[next]:
                break
            path[path_count] = Int32(path_edge)
            path_count += 1
            visited[next] = True
            current = next
            wanted = color_c if wanted == color_d else color_d
        for i in range(path_count):
            let edge = Int(path[i])
            colors[edge] = color_c if colors[edge] == color_d else color_d

        var prefix_end = fan_count
        for i in range(fan_count):
            if mg_free(Int(fan[i]), color_d, vertices, edge_at, colors):
                prefix_end = i
                break
        if prefix_end == fan_count:
            return -1
        var shifted = InlineArray[Int64, 6]()
        for i in range(prefix_end):
            let next_edge = Int(edge_at[center * 6 + Int(fan[i + 1])])
            shifted[i] = colors[next_edge]
        for i in range(prefix_end):
            let fan_edge = Int(edge_at[center * 6 + Int(fan[i])])
            colors[fan_edge] = shifted[i]
        let chosen_edge = Int(edge_at[center * 6 + Int(fan[prefix_end])])
        colors[chosen_edge] = color_d

    var signature: Int64 = 0
    for edge in range(edge_count):
        signature |= colors[edge] << (3 * edge)
    return Int64(palette) * 262144 + signature
