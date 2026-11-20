package khuller_raghavachari_three_edge_connected_spanning_subgraph
import "core:c"

MAX_N :: 8
MAX_M :: 28
MAX_INPUT :: 59

put :: proc(out: [^]u8, at: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { out[at+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
khuller_raghavachari_three_edge_connected_spanning_subgraph :: proc "c"(
    input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT do return -1
    n64, m64 := input[0], input[1]
    if n64 < 4 || n64 > 8 || m64 < 6 || m64 > 28 do return -1
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
    full := (1 << n) - 1
    for side := 1; side < full; side += 1 {
        if (side & 1) == 0 do continue
        cut := 0
        for edge := 0; edge < m; edge += 1 {
            if ((side >> u[edge]) & 1) != ((side >> v[edge]) & 1) { cut += 1 }
        }
        if cut < 3 do return -1
    }

    selected: [MAX_M]bool
    state: [MAX_N]int
    discovery: [MAX_N]int
    finish: [MAX_N]int
    parent: [MAX_N]int
    parent_edge: [MAX_N]int
    postorder: [MAX_N]int
    stack_vertex: [MAX_N]int
    stack_slot: [MAX_N]int
    post_count := 0
    clock := 1
    top := 1
    state[0] = 1
    discovery[0] = 0
    parent[0] = n
    parent_edge[0] = m
    stack_vertex[0] = 0
    for top > 0 {
        frame := top - 1
        x := stack_vertex[frame]
        if stack_slot[frame] < m {
            edge := stack_slot[frame]
            stack_slot[frame] += 1
            y := n
            if u[edge] == x { y = v[edge] } else if v[edge] == x { y = u[edge] }
            if y == n || state[y] != 0 do continue
            selected[edge] = true
            state[y] = 1
            parent[y] = x
            parent_edge[y] = edge
            discovery[y] = clock
            clock += 1
            stack_vertex[top] = y
            stack_slot[top] = 0
            top += 1
            continue
        }
        state[x] = 2
        finish[x] = clock
        if parent_edge[x] < m { postorder[post_count] = parent_edge[x]; post_count += 1 }
        top -= 1
    }

    for position := 0; position < post_count; position += 1 {
        tree_edge := postorder[position]
        child := v[tree_edge]
        if parent_edge[u[tree_edge]] == tree_edge { child = u[tree_edge] }
        upper := parent[child]
        separated := false
        for removed := 0; removed < m; removed += 1 {
            if separated || !selected[removed] do continue
            seen: [MAX_N]bool
            queue: [MAX_N]int
            head := 0
            tail := 1
            seen[upper] = true
            queue[0] = upper
            for head < tail {
                current := queue[head]
                head += 1
                for edge := 0; edge < m; edge += 1 {
                    if !selected[edge] || edge == removed do continue
                    next := n
                    if u[edge] == current { next = v[edge] } else if v[edge] == current { next = u[edge] }
                    if next < n && !seen[next] { seen[next] = true; queue[tail] = next; tail += 1 }
                }
            }
            if !seen[child] { separated = true }
        }
        if !separated do continue
        candidate := m
        earliest := n
        for edge := 0; edge < m; edge += 1 {
            if selected[edge] do continue
            u_inside := discovery[child] <= discovery[u[edge]] && discovery[u[edge]] < finish[child]
            v_inside := discovery[child] <= discovery[v[edge]] && discovery[v[edge]] < finish[child]
            if u_inside == v_inside do continue
            ancestor := u[edge]
            if u_inside { ancestor = v[edge] }
            if discovery[ancestor] < earliest { earliest = discovery[ancestor]; candidate = edge }
        }
        if candidate == m do return -1
        selected[candidate] = true
    }

    leader: [MAX_N]int
    for vertex := 0; vertex < n; vertex += 1 { leader[vertex] = vertex }
    for edge := 0; edge < m; edge += 1 {
        if selected[edge] do continue
        a, b := u[edge], v[edge]
        for leader[a] != a { leader[a] = leader[leader[a]]; a = leader[a] }
        for leader[b] != b { leader[b] = leader[leader[b]]; b = leader[b] }
        if a != b { leader[b] = a; selected[edge] = true }
    }
    count := 0
    for edge := 0; edge < m; edge += 1 { if selected[edge] { count += 1 } }
    bytes := 8 * (1 + 2*count)
    if output == nil || capacity < c.size_t(bytes) do return -2
    put(output, 0, i64(count))
    slot := 0
    for edge := 0; edge < m; edge += 1 {
        if !selected[edge] do continue
        put(output, 8*(1+2*slot), i64(u[edge]))
        put(output, 8*(2+2*slot), i64(v[edge]))
        slot += 1
    }
    return i64(bytes)
}
