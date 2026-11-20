package cheriyan_thurimella_two_vertex_connected_augmentation
import "core:c"

MAX_N :: 8
MAX_M :: 28
MAX_INPUT :: 59
MAX_STATES :: 256

put :: proc(out: [^]u8, at: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { out[at+byte] = u8(bits & 255); bits >>= 8 }
}

biconnected :: proc(n, m: int, u, v: [MAX_M]int, active: [MAX_M]bool) -> bool {
    for removed := 0; removed < n; removed += 1 {
        seen: [MAX_N]bool
        queue: [MAX_N]int
        start := 0
        if removed == 0 { start = 1 }
        head := 0
        tail := 1
        seen[start] = true
        queue[0] = start
        for head < tail {
            current := queue[head]
            head += 1
            for edge := 0; edge < m; edge += 1 {
                if !active[edge] || u[edge] == removed || v[edge] == removed do continue
                next := n
                if u[edge] == current { next = v[edge] }
                else if v[edge] == current { next = u[edge] }
                if next < n && !seen[next] {
                    seen[next] = true
                    queue[tail] = next
                    tail += 1
                }
            }
        }
        for vertex := 0; vertex < n; vertex += 1 {
            if vertex != removed && !seen[vertex] do return false
        }
    }
    return true
}

@(export)
cheriyan_thurimella_two_vertex_connected_augmentation :: proc "c"(
    input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT do return -1
    n64, m64 := input[0], input[1]
    if n64 < 3 || n64 > 8 || m64 < 3 || m64 > 28 do return -1
    n, m := int(n64), int(m64)
    if length != c.size_t(2 + 2*m) do return -1
    u: [MAX_M]int
    v: [MAX_M]int
    for edge := 0; edge < m; edge += 1 {
        a, b := input[2+2*edge], input[3+2*edge]
        if a < 0 || a >= b || b >= n64 do return -1
        u[edge], v[edge] = int(a), int(b)
        for prior := 0; prior < edge; prior += 1 {
            if u[prior] == u[edge] && v[prior] == v[edge] do return -1
        }
    }
    active: [MAX_M]bool
    for edge := 0; edge < m; edge += 1 { active[edge] = true }
    if !biconnected(n, m, u, v, active) do return -1

    states := 1 << n
    best: [MAX_STATES]int
    choice: [MAX_STATES]int
    for mask := 0; mask < states; mask += 1 { choice[mask] = -1 }
    for mask := 1; mask < states; mask += 1 {
        first := 0
        for (mask & (1 << first)) == 0 { first += 1 }
        for edge := 0; edge < m; edge += 1 {
            other := n
            if u[edge] == first { other = v[edge] }
            else if v[edge] == first { other = u[edge] }
            if other == n || (mask & (1 << other)) == 0 do continue
            rest := mask & ~(1 << first) & ~(1 << other)
            candidate := 1 + best[rest]
            if candidate > best[mask] { best[mask] = candidate; choice[mask] = edge }
        }
        rest := mask & ~(1 << first)
        if best[rest] > best[mask] { best[mask] = best[rest]; choice[mask] = -1 }
    }
    cover: [MAX_M]bool
    covered: [MAX_N]bool
    mask := states - 1
    for mask != 0 {
        first := 0
        for (mask & (1 << first)) == 0 { first += 1 }
        edge := choice[mask]
        if edge < 0 { mask &= ~(1 << first); continue }
        cover[edge] = true
        covered[u[edge]], covered[v[edge]] = true, true
        mask &= ~(1 << u[edge]) & ~(1 << v[edge])
    }
    for vertex := 0; vertex < n; vertex += 1 {
        if covered[vertex] do continue
        for edge := 0; edge < m; edge += 1 {
            if u[edge] == vertex || v[edge] == vertex {
                cover[edge] = true
                covered[u[edge]], covered[v[edge]] = true, true
                break
            }
        }
    }
    for edge := 0; edge < m; edge += 1 {
        if cover[edge] do continue
        active[edge] = false
        if !biconnected(n, m, u, v, active) { active[edge] = true }
    }
    count := 0
    for edge := 0; edge < m; edge += 1 { if active[edge] { count += 1 } }
    bytes := 8 * (1 + 2*count)
    if output == nil || capacity < c.size_t(bytes) do return -2
    put(output, 0, i64(count))
    slot := 0
    for edge := 0; edge < m; edge += 1 {
        if !active[edge] do continue
        put(output, 8*(1+2*slot), i64(u[edge]))
        put(output, 8*(2+2*slot), i64(v[edge]))
        slot += 1
    }
    return i64(bytes)
}
