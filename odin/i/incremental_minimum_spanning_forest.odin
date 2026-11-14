package incremental_minimum_spanning_forest
import "core:c"

@(export)
incremental_minimum_spanning_forest :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 98 do return -1
    n64 := input[0]; m64 := input[1]
    if n64 < 1 || n64 > 16 || m64 < 1 || m64 > 32 || length != c.size_t(2 + 3*m64) do return -1
    n := int(n64); m := int(m64)
    for i := 0; i < m; i += 1 {
        u := input[2+3*i]; v := input[3+3*i]; w := input[4+3*i]
        if u < 0 || u >= n64 || v < 0 || v >= n64 || w < 1 || w > 1000000 do return -1
        for j := 0; j < i; j += 1 { if input[4+3*j] == w do return -1 }
    }
    active: [32]bool; answers: [32]i64
    for edge := 0; edge < m; edge += 1 {
        start := int(input[2+3*edge]); target := int(input[3+3*edge])
        if start == target { answers[edge] = i64(edge); continue }
        parent: [16]int; parent_edge: [16]int; queue: [16]int
        for i := 0; i < n; i += 1 { parent[i] = -1 }
        head := 0; tail := 1; queue[0] = start; parent[start] = start
        for head < tail {
            vertex := queue[head]; head += 1
            for i := 0; i < edge; i += 1 {
                if !active[i] { continue }
                u := int(input[2+3*i]); v := int(input[3+3*i]); neighbor := -1
                if u == vertex { neighbor = v } else if v == vertex { neighbor = u }
                if neighbor >= 0 && parent[neighbor] < 0 {
                    parent[neighbor] = vertex; parent_edge[neighbor] = i
                    queue[tail] = neighbor; tail += 1
                }
            }
        }
        if parent[target] < 0 { active[edge] = true; answers[edge] = -1; continue }
        node := target; heaviest := parent_edge[node]
        for node != start {
            i := parent_edge[node]
            if input[4+3*i] > input[4+3*heaviest] { heaviest = i }
            node = parent[node]
        }
        if input[4+3*edge] < input[4+3*heaviest] {
            active[heaviest] = false; active[edge] = true; answers[edge] = i64(heaviest)
        } else { answers[edge] = i64(edge) }
    }
    bytes := 8*m
    if output == nil || capacity < c.size_t(bytes) do return -2
    for i := 0; i < m; i += 1 {
        bits := transmute(u64)answers[i]
        for b := 0; b < 8; b += 1 { output[8*i+b] = u8((bits >> u64(8*b)) & 255) }
    }
    return i64(bytes)
}
