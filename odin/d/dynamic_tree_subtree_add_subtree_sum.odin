package dynamic_tree_subtree_add_subtree_sum

import "core:c"

MAX_N :: 16
MAX_Q :: 32
MAX_TOKENS :: MAX_N + 2 * (MAX_N - 1 + MAX_Q)
MAX_INPUT :: 3 * MAX_N + 5 * MAX_Q + 1
MAX_DELTA :: i64(1000)

Tour_Node :: struct {
    left, right, parent: int,
    priority: u32,
    sequence_size, marker_count: int,
    marker: bool,
    own_value, sum, lazy_add: i64,
}
Tour :: struct {
    nodes: [MAX_TOKENS]Tour_Node,
    next_node: int,
    random_state: u32,
}

seq_size :: proc "contextless" (tour: ^Tour, id: int) -> int {
    if id < 0 do return 0
    return tour.nodes[id].sequence_size
}
marker_count :: proc "contextless" (tour: ^Tour, id: int) -> int {
    if id < 0 do return 0
    return tour.nodes[id].marker_count
}
node_sum :: proc "contextless" (tour: ^Tour, id: int) -> i64 {
    if id < 0 do return 0
    return tour.nodes[id].sum
}
pull :: proc "contextless" (tour: ^Tour, id: int) {
    n := tour.nodes[id]
    tour.nodes[id].sequence_size = 1 + seq_size(tour, n.left) + seq_size(tour, n.right)
    tour.nodes[id].marker_count = int(n.marker) + marker_count(tour, n.left) + marker_count(tour, n.right)
    tour.nodes[id].sum = n.own_value + node_sum(tour, n.left) + node_sum(tour, n.right)
}
apply_add :: proc "contextless" (tour: ^Tour, id: int, delta: i64) {
    if id < 0 || tour.nodes[id].marker_count == 0 do return
    tour.nodes[id].sum += delta * i64(tour.nodes[id].marker_count)
    if tour.nodes[id].marker do tour.nodes[id].own_value += delta
    tour.nodes[id].lazy_add += delta
}
push :: proc "contextless" (tour: ^Tour, id: int) {
    delta := tour.nodes[id].lazy_add
    if delta == 0 do return
    apply_add(tour, tour.nodes[id].left, delta)
    apply_add(tour, tour.nodes[id].right, delta)
    tour.nodes[id].lazy_add = 0
}
next_priority :: proc "contextless" (tour: ^Tour) -> u32 {
    x := tour.random_state
    x = x ^ (x << 13)
    x = x ^ (x >> 17)
    x = x ^ (x << 5)
    tour.random_state = x
    return x
}
new_node :: proc "contextless" (tour: ^Tour, marker: bool, value: i64) -> int {
    if tour.next_node >= MAX_TOKENS do return -1
    id := tour.next_node
    tour.next_node += 1
    tour.nodes[id] = Tour_Node{
        left = -1, right = -1, parent = -1, priority = next_priority(tour),
        sequence_size = 1, marker_count = int(marker), marker = marker,
        own_value = (if marker do value else 0), sum = (if marker do value else 0),
    }
    return id
}
split :: proc "contextless" (tour: ^Tour, root, count: int) -> (int, int) {
    if root < 0 do return -1, -1
    push(tour, root)
    tour.nodes[root].parent = -1
    left := tour.nodes[root].left
    if seq_size(tour, left) >= count {
        first, middle := split(tour, left, count)
        tour.nodes[root].left = middle
        if middle >= 0 do tour.nodes[middle].parent = root
        pull(tour, root)
        if first >= 0 do tour.nodes[first].parent = -1
        tour.nodes[root].parent = -1
        return first, root
    }
    right := tour.nodes[root].right
    middle, second := split(tour, right, count - seq_size(tour, left) - 1)
    tour.nodes[root].right = middle
    if middle >= 0 do tour.nodes[middle].parent = root
    pull(tour, root)
    tour.nodes[root].parent = -1
    if second >= 0 do tour.nodes[second].parent = -1
    return root, second
}
merge :: proc "contextless" (tour: ^Tour, first, second: int) -> int {
    if first < 0 {
        if second >= 0 do tour.nodes[second].parent = -1
        return second
    }
    if second < 0 { tour.nodes[first].parent = -1; return first }
    tour.nodes[first].parent = -1
    tour.nodes[second].parent = -1
    if tour.nodes[first].priority >= tour.nodes[second].priority {
        push(tour, first)
        joined := merge(tour, tour.nodes[first].right, second)
        tour.nodes[first].right = joined
        if joined >= 0 do tour.nodes[joined].parent = first
        pull(tour, first)
        tour.nodes[first].parent = -1
        return first
    }
    push(tour, second)
    joined := merge(tour, first, tour.nodes[second].left)
    tour.nodes[second].left = joined
    if joined >= 0 do tour.nodes[joined].parent = second
    pull(tour, second)
    tour.nodes[second].parent = -1
    return second
}
root_of :: proc "contextless" (tour: ^Tour, start: int) -> int {
    id := start
    for tour.nodes[id].parent >= 0 { id = tour.nodes[id].parent }
    return id
}
rank_of :: proc "contextless" (tour: ^Tour, start: int) -> int {
    id := start
    rank := seq_size(tour, tour.nodes[id].left)
    for tour.nodes[id].parent >= 0 {
        parent := tour.nodes[id].parent
        if tour.nodes[parent].right == id do rank += 1 + seq_size(tour, tour.nodes[parent].left)
        id = parent
    }
    return rank
}
rotate_to :: proc "contextless" (tour: ^Tour, id: int) -> int {
    first, second := split(tour, root_of(tour, id), rank_of(tour, id))
    return merge(tour, second, first)
}
link_tours :: proc "contextless" (tour: ^Tour, markers: [MAX_N]int, u, v: int,
                                  uv, vu: ^int) -> bool {
    root_u := root_of(tour, markers[u])
    root_v := root_of(tour, markers[v])
    if root_u == root_v do return false
    a0, a1 := split(tour, root_u, rank_of(tour, markers[u]) + 1)
    b0, tail := split(tour, root_v, rank_of(tour, markers[v]))
    vm, b1 := split(tour, tail, 1)
    uv^ = new_node(tour, false, 0)
    vu^ = new_node(tour, false, 0)
    if uv^ < 0 || vu^ < 0 do return false
    root := merge(tour, a0, uv^)
    root = merge(tour, root, b1)
    root = merge(tour, root, b0)
    root = merge(tour, root, vm)
    root = merge(tour, root, vu^)
    _ = merge(tour, root, a1)
    return true
}
cut_tours :: proc "contextless" (tour: ^Tour, uv, vu: int) -> bool {
    root := rotate_to(tour, uv)
    reverse_rank := rank_of(tour, vu)
    if reverse_rank == 0 do return false
    first, rest := split(tour, root, 1)
    _, tail := split(tour, rest, reverse_rank - 1)
    reverse, _ := split(tour, tail, 1)
    if first != uv || reverse != vu do return false
    tour.nodes[uv].left = -1; tour.nodes[uv].right = -1; tour.nodes[uv].parent = -1
    tour.nodes[vu].left = -1; tour.nodes[vu].right = -1; tour.nodes[vu].parent = -1
    return true
}
side_operation :: proc "contextless" (tour: ^Tour, uv, vu: int, update: bool,
                                       delta: i64, answer: ^i64) -> bool {
    root := rotate_to(tour, uv)
    reverse_rank := rank_of(tour, vu)
    if reverse_rank == 0 do return false
    edge, rest := split(tour, root, 1)
    side, tail := split(tour, rest, reverse_rank - 1)
    if edge != uv || side < 0 do return false
    if update do apply_add(tour, side, delta) else answer^ = node_sum(tour, side)
    joined := merge(tour, edge, side)
    _ = merge(tour, joined, tail)
    return true
}
connected :: proc "contextless" (adjacency: ^[MAX_N*MAX_N]bool, n, start, goal: int) -> bool {
    seen: [MAX_N]bool = {}
    queue: [MAX_N]int
    head, tail := 0, 1
    queue[0] = start
    seen[start] = true
    for head < tail {
        u := queue[head]
        head += 1
        if u == goal do return true
        for v := 0; v < n; v += 1 {
            if adjacency^[u*MAX_N+v] && !seen[v] { seen[v] = true; queue[tail] = v; tail += 1 }
        }
    }
    return false
}
validate_fields :: proc "contextless" (input: [^]i64, n, q: int, queries: ^int) -> bool {
    for i := 0; i < n; i += 1 { if input[2+i] < 0 || input[2+i] > MAX_DELTA do return false }
    edge_start := 2 + n
    for i := 0; i < n-1; i += 1 {
        u, v := input[edge_start+2*i], input[edge_start+2*i+1]
        if u < 0 || u >= i64(n) || v < 0 || v >= i64(n) || u == v do return false
    }
    operations := edge_start + 2*(n-1)
    queries^ = 0
    for i := 0; i < q; i += 1 {
        at := operations + 5*i
        kind, v, p, a, b := input[at], input[at+1], input[at+2], input[at+3], input[at+4]
        if kind == 0 {
            if v < 0 || v >= i64(n) || p < 0 || p >= i64(n) || a < 0 || a >= i64(n) || b < 0 || b >= i64(n) || v == p || a == b do return false
        } else if kind == 1 {
            if v < 0 || v >= i64(n) || p < 0 || p >= i64(n) || v == p || a < 0 || a > MAX_DELTA || b != 0 do return false
        } else if kind == 2 {
            if v < 0 || v >= i64(n) || p < 0 || p >= i64(n) || v == p || a != 0 || b != 0 do return false
            queries^ += 1
        } else do return false
    }
    return true
}
validate_topology :: proc "contextless" (input: [^]i64, n, q: int) -> bool {
    adjacency: [MAX_N*MAX_N]bool = {}
    edge_start := 2+n
    operations := edge_start + 2*(n-1)
    for i := 0; i < n-1; i += 1 {
        u, v := int(input[edge_start+2*i]), int(input[edge_start+2*i+1])
        if adjacency[u*MAX_N+v] do return false
        adjacency[u*MAX_N+v] = true; adjacency[v*MAX_N+u] = true
    }
    for v := 0; v < n; v += 1 { if !connected(&adjacency, n, 0, v) do return false }
    for i := 0; i < q; i += 1 {
        at := operations + 5*i
        kind, v, p := int(input[at]), int(input[at+1]), int(input[at+2])
        if kind == 0 {
            a, b := int(input[at+3]), int(input[at+4])
            if !adjacency[v*MAX_N+p] do return false
            adjacency[v*MAX_N+p] = false; adjacency[p*MAX_N+v] = false
            if connected(&adjacency, n, a, b) do return false
            adjacency[a*MAX_N+b] = true; adjacency[b*MAX_N+a] = true
        } else if !adjacency[v*MAX_N+p] do return false
    }
    return true
}
put_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := transmute(u64)value
    for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> (8*byte)) }
}

@(export)
dynamic_tree_subtree_add_subtree_sum :: proc "c" (input: [^]i64, input_length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 2 || input_length > MAX_INPUT do return -1
    n_value, q_value := input[0], input[1]
    if n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q do return -1
    n, q := int(n_value), int(q_value)
    if int(input_length) != 3*n+5*q do return -1
    queries := 0
    if !validate_fields(input, n, q, &queries) || !validate_topology(input, n, q) do return -1
    output_bytes := 8*queries
    if output_bytes > 0 && (output == nil || int(output_capacity) < output_bytes) do return -2

    tour := Tour{}
    tour.random_state = 0x9e3779b9
    markers: [MAX_N]int
    for i := 0; i < n; i += 1 { markers[i] = new_node(&tour, true, input[2+i]) }
    directed: [MAX_N*MAX_N]int
    for i := 0; i < len(directed); i += 1 { directed[i] = -1 }
    edge_start := 2+n
    operations := edge_start + 2*(n-1)
    for i := 0; i < n-1; i += 1 {
        u, v := int(input[edge_start+2*i]), int(input[edge_start+2*i+1])
        uv, vu: int
        if !link_tours(&tour, markers, u, v, &uv, &vu) do return -1
        directed[u*MAX_N+v] = uv; directed[v*MAX_N+u] = vu
    }
    answers: [MAX_Q]i64
    answer_count := 0
    for i := 0; i < q; i += 1 {
        at := operations + 5*i
        kind, v, p := int(input[at]), int(input[at+1]), int(input[at+2])
        if kind == 0 {
            a, b := int(input[at+3]), int(input[at+4])
            uv, vu := directed[v*MAX_N+p], directed[p*MAX_N+v]
            if uv < 0 || vu < 0 || !cut_tours(&tour, uv, vu) do return -1
            directed[v*MAX_N+p] = -1; directed[p*MAX_N+v] = -1
            new_uv, new_vu: int
            if !link_tours(&tour, markers, a, b, &new_uv, &new_vu) do return -1
            directed[a*MAX_N+b] = new_uv; directed[b*MAX_N+a] = new_vu
        } else if kind == 1 {
            ignored: i64
            if !side_operation(&tour, directed[p*MAX_N+v], directed[v*MAX_N+p], true, input[at+3], &ignored) do return -1
        } else {
            answer: i64
            if !side_operation(&tour, directed[p*MAX_N+v], directed[v*MAX_N+p], false, 0, &answer) do return -1
            answers[answer_count] = answer
            answer_count += 1
        }
    }
    for i := 0; i < answer_count; i += 1 { put_i64(output, 8*i, answers[i]) }
    return i64(output_bytes)
}
