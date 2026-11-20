package two_vertex_connected_spanning_subgraph_khuller_vishkin_dfs
import "core:c"

MAX_N :: 8
MAX_M :: 28
MAX_INPUT :: 59

put :: proc(out: [^]u8, at: int, value: i64) {
    bits := u64(value)
    for i := 0; i < 8; i += 1 { out[at+i] = u8(bits & 255); bits >>= 8 }
}
connected_without_vertex :: proc(n, m: int, u, v: [^]int, removed: int) -> bool {
    seen: [MAX_N]bool
    queue: [MAX_N]int
    head, tail := 0, 1
    start := 0
    if removed == 0 { start = 1 }
    queue[0] = start
    seen[start] = true
    for head < tail {
        x := queue[head]
        head += 1
        for e := 0; e < m; e += 1 {
            if u[e] == removed || v[e] == removed do continue
            y := MAX_N
            if u[e] == x { y = v[e] } else if v[e] == x { y = u[e] }
            if y < n && !seen[y] { seen[y] = true; queue[tail] = y; tail += 1 }
        }
    }
    for i := 0; i < n; i += 1 { if i != removed && !seen[i] do return false }
    return true
}
earlier :: proc(a, b: int, disc: [^]int) -> bool { return disc[a] < disc[b] }

@(export)
two_vertex_connected_spanning_subgraph_khuller_vishkin_dfs :: proc "c"(
    input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT do return -1
    n64, m64 := input[0], input[1]
    if n64 < 3 || n64 > 8 || m64 < 3 || m64 > 28 || length != c.size_t(2+2*m64) do return -1
    n, m := int(n64), int(m64)
    u: [MAX_M]int
    v: [MAX_M]int
    for e := 0; e < m; e += 1 {
        a, b := input[2+2*e], input[3+2*e]
        if a < 0 || a >= b || b >= n64 do return -1
        u[e], v[e] = int(a), int(b)
        for j := 0; j < e; j += 1 { if u[j] == u[e] && v[j] == v[e] do return -1 }
    }
    for removed := 0; removed < n; removed += 1 {
        if !connected_without_vertex(n, m, &u[0], &v[0], removed) do return -1
    }

    state: [MAX_N]int
    disc: [MAX_N]int
    low: [MAX_N]int
    low_h: [MAX_N]int
    savior: [MAX_N]int
    selected: [MAX_M]bool
    parent_edge: [MAX_N]int
    stack_v: [MAX_N]int
    stack_parent: [MAX_N]int
    stack_cursor: [MAX_N]int
    tick, top := 1, 1
    state[0] = 1
    disc[0], low[0], low_h[0], savior[0] = 0, 0, 0, 0
    stack_v[0], stack_parent[0], stack_cursor[0] = 0, MAX_N, 0
    for top > 0 {
        frame := top - 1
        x, parent := stack_v[frame], stack_parent[frame]
        if stack_cursor[frame] < m {
            e := stack_cursor[frame]
            stack_cursor[frame] += 1
            y := MAX_N
            if u[e] == x { y = v[e] } else if v[e] == x { y = u[e] }
            if y == MAX_N do continue
            if state[y] == 0 {
                selected[e] = true
                parent_edge[y] = e
                state[y] = 1
                disc[y] = tick
                tick += 1
                low[y], low_h[y], savior[y] = y, y, y
                stack_v[top], stack_parent[top], stack_cursor[top] = y, x, 0
                top += 1
            } else if state[y] == 1 && y != parent && earlier(y, low[x], &disc[0]) {
                low[x], savior[x] = y, x
            }
            continue
        }
        state[x] = 2
        if parent < n && low_h[x] == x {
            lo, hi := min(savior[x], low[x]), max(savior[x], low[x])
            for e := 0; e < m; e += 1 {
                if u[e] == lo && v[e] == hi { selected[e] = true; break }
            }
            low_h[x] = low[x]
        }
        if parent < n && low_h[x] == parent {
            lo, hi := min(savior[x], low[x]), max(savior[x], low[x])
            for e := 0; e < m; e += 1 {
                if u[e] == lo && v[e] == hi { selected[e] = true; break }
            }
            low_h[x] = low[x]
            if savior[x] == x { selected[parent_edge[x]] = false }
        }
        top -= 1
        if parent < n {
            if earlier(low[x], low[parent], &disc[0]) { low[parent], savior[parent] = low[x], savior[x] }
            if earlier(low_h[x], low_h[parent], &disc[0]) { low_h[parent] = low_h[x] }
        }
    }
    count := 0
    for e := 0; e < m; e += 1 { if selected[e] { count += 1 } }
    bytes := 8 * (1 + 2*count)
    if output == nil || capacity < c.size_t(bytes) do return -2
    put(output, 0, i64(count))
    at := 8
    for a := 0; a < n; a += 1 { for b := a+1; b < n; b += 1 { for e := 0; e < m; e += 1 {
        if selected[e] && u[e] == a && v[e] == b { put(output, at, i64(a)); put(output, at+8, i64(b)); at += 16 }
    } } }
    return i64(bytes)
}
