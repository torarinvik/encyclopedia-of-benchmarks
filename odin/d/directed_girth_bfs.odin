package directed_girth_bfs

import "core:c"

@(export)
directed_girth_bfs :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 131 do return -1
    if input[0] < 1 || input[0] > 16 || input[1] < 0 || input[1] > 64 do return -1
    n, m := int(input[0]), int(input[1])
    if length != c.size_t(2+2*m) do return -1
    outgoing: [16]u32
    for i := 0; i < m; i += 1 {
        u, v := input[2+2*i], input[3+2*i]
        if u < 0 || v < 0 || u >= i64(n) || v >= i64(n) do return -1
        outgoing[int(u)] |= u32(1) << uint(v)
    }
    best := 17
    for start := 0; start < n; start += 1 {
        distance: [16]int
        queue: [16]int
        for i := 0; i < n; i += 1 { distance[i] = -1 }
        distance[start] = 0; queue[0] = start
        head, tail := 0, 1
        for head < tail {
            u := queue[head]; head += 1
            for v := 0; v < n; v += 1 {
                if outgoing[u] & (u32(1) << uint(v)) == 0 do continue
                if v == start {
                    if distance[u]+1 < best { best = distance[u]+1 }
                } else if distance[v] < 0 {
                    distance[v] = distance[u]+1; queue[tail] = v; tail += 1
                }
            }
        }
    }
    if best == 17 do return 0
    return i64(best)
}
