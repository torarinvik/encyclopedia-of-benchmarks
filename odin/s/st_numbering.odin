package st_numbering

import "core:c"

MAX_VERTICES :: 8
MAX_EDGES :: 28
MAX_ARCS :: 2 * MAX_EDGES
MAX_INPUT :: 4 + 2 * MAX_EDGES

@(export)
st_numbering :: proc "c" (input: [^]i64, input_length: c.size_t,
                            output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 4 || input_length > MAX_INPUT do return -1
    n_value, m_value, s_value, t_value := input[0], input[1], input[2], input[3]
    if n_value < 2 || n_value > MAX_VERTICES || m_value < 0 || m_value > MAX_EDGES ||
        s_value < 0 || s_value >= n_value || t_value < 0 || t_value >= n_value ||
        s_value == t_value || input_length != c.size_t(4 + 2 * m_value) do return -1
    n, m, s, t := int(n_value), int(m_value), int(s_value), int(t_value)

    edge_u, edge_v: [MAX_EDGES]int
    adjacent: [MAX_VERTICES]u16
    st_edge := -1
    for edge := 0; edge < m; edge += 1 {
        u_value := input[4 + 2 * edge]
        v_value := input[5 + 2 * edge]
        if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value do return -1
        u, v := int(u_value), int(v_value)
        u_bit := u16(1) << u32(v)
        v_bit := u16(1) << u32(u)
        if adjacent[u]&u_bit != 0 do return -1
        adjacent[u] |= u_bit
        adjacent[v] |= v_bit
        edge_u[edge], edge_v[edge] = u, v
        if (u == s && v == t) || (u == t && v == s) do st_edge = edge
    }
    if st_edge < 0 do return -1

    head: [MAX_VERTICES]int
    for vertex := 0; vertex < n; vertex += 1 { head[vertex] = -1 }
    arc_to, arc_next: [MAX_ARCS]int
    arc_count := 0
    for edge := 0; edge < m; edge += 1 {
        if edge == st_edge do continue
        u, v := edge_u[edge], edge_v[edge]
        arc_to[arc_count], arc_next[arc_count], head[u] = v, head[u], arc_count
        arc_count += 1
        arc_to[arc_count], arc_next[arc_count], head[v] = u, head[v], arc_count
        arc_count += 1
    }
    arc_to[arc_count], arc_next[arc_count], head[s] = t, head[s], arc_count
    arc_count += 1
    arc_to[arc_count], arc_next[arc_count], head[t] = s, head[t], arc_count

    parent, discovery, low_vertex, children, next_arc, preorder: [MAX_VERTICES]int
    for vertex := 0; vertex < n; vertex += 1 {
        parent[vertex] = -1
        low_vertex[vertex] = vertex
        next_arc[vertex] = -1
    }
    stack: [MAX_VERTICES]int
    top, clock, preorder_count := 0, 1, 1
    discovery[s], preorder[0], next_arc[s] = clock, s, head[s]
    stack[top] = s
    top += 1
    for top > 0 {
        vertex := stack[top-1]
        arc := next_arc[vertex]
        if arc < 0 {
            top -= 1
            ancestor := parent[vertex]
            if ancestor >= 0 && discovery[low_vertex[vertex]] < discovery[low_vertex[ancestor]] {
                low_vertex[ancestor] = low_vertex[vertex]
            }
            continue
        }
        next_arc[vertex] = arc_next[arc]
        neighbor := arc_to[arc]
        if neighbor == parent[vertex] do continue
        if discovery[neighbor] == 0 {
            parent[neighbor] = vertex
            children[vertex] += 1
            clock += 1
            discovery[neighbor] = clock
            low_vertex[neighbor] = neighbor
            preorder[preorder_count] = neighbor
            preorder_count += 1
            next_arc[neighbor] = head[neighbor]
            stack[top] = neighbor
            top += 1
        } else if discovery[neighbor] < discovery[vertex] &&
                  discovery[neighbor] < discovery[low_vertex[vertex]] {
            low_vertex[vertex] = neighbor
        }
    }
    if preorder_count != n || children[s] != 1 do return -1
    for vertex := 0; vertex < n; vertex += 1 {
        if vertex == s do continue
        for child := 0; child < n; child += 1 {
            if parent[child] == vertex && discovery[low_vertex[child]] >= discovery[vertex] do return -1
        }
    }

    previous, following, sign: [MAX_VERTICES]int
    for vertex := 0; vertex < n; vertex += 1 { previous[vertex], following[vertex] = -1, -1 }
    sign[s], following[s], previous[t] = -1, t, s
    list_head := s
    for order := 2; order < n; order += 1 {
        vertex := preorder[order]
        ancestor := parent[vertex]
        if sign[low_vertex[vertex]] == -1 {
            left := previous[ancestor]
            previous[vertex], following[vertex], previous[ancestor] = left, ancestor, vertex
            if left >= 0 { following[left] = vertex } else { list_head = vertex }
            sign[ancestor] = 1
        } else {
            right := following[ancestor]
            previous[vertex], following[vertex], following[ancestor] = ancestor, right, vertex
            if right >= 0 { previous[right] = vertex }
            sign[ancestor] = -1
        }
    }

    rank: [MAX_VERTICES]int
    staged: [MAX_VERTICES]u8
    rank_value, vertex := 1, list_head
    for vertex >= 0 && rank_value <= n {
        rank[vertex] = rank_value
        staged[vertex] = u8(rank_value)
        rank_value += 1
        vertex = following[vertex]
    }
    if rank_value != n+1 || rank[s] != 1 || rank[t] != n do return -1
    for v := 0; v < n; v += 1 {
        if v == s || v == t do continue
        lower, higher := false, false
        for arc := head[v]; arc >= 0; arc = arc_next[arc] {
            neighbor := arc_to[arc]
            lower = lower || rank[neighbor] < rank[v]
            higher = higher || rank[neighbor] > rank[v]
        }
        if !lower || !higher do return -1
    }
    if output == nil || output_capacity < c.size_t(n) do return -2
    for v := 0; v < n; v += 1 { output[v] = staged[v] }
    return i64(n)
}
