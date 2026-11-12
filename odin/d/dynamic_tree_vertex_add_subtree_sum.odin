package dynamic_tree_vertex_add_subtree_sum

import "core:c"

MAX_N :: 32
MAX_Q :: 64
MAX_INPUT :: 3 * MAX_N + 5 * MAX_Q + 1
MAX_VALUE :: 1000

Lct_Node :: struct {
    left, right, parent: int,
    reversed: bool,
    value, virtual_sum, sum: i64,
}

is_aux_root :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, x: int) -> bool {
    p := nodes^[x].parent
    return p < 0 || (nodes^[p].left != x && nodes^[p].right != x)
}
node_sum :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, x: int) -> i64 {
    if x < 0 do return 0
    return nodes^[x].sum
}
pull :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, x: int) {
    nodes^[x].sum = nodes^[x].value + nodes^[x].virtual_sum + node_sum(nodes, nodes^[x].left) + node_sum(nodes, nodes^[x].right)
}
toggle_reverse :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, x: int) {
    if x < 0 do return
    temp := nodes^[x].left
    nodes^[x].left = nodes^[x].right
    nodes^[x].right = temp
    nodes^[x].reversed = !nodes^[x].reversed
}
push :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, x: int) {
    if !nodes^[x].reversed do return
    toggle_reverse(nodes, nodes^[x].left)
    toggle_reverse(nodes, nodes^[x].right)
    nodes^[x].reversed = false
}
rotate :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, x: int) {
    p := nodes^[x].parent
    g := nodes^[p].parent
    right_child := nodes^[p].right == x
    middle := nodes^[x].right
    if right_child do middle = nodes^[x].left
    if !is_aux_root(nodes, p) {
        if nodes^[g].left == p do nodes^[g].left = x else nodes^[g].right = x
    }
    nodes^[x].parent = g
    if right_child {
        nodes^[x].left = p
        nodes^[p].right = middle
    } else {
        nodes^[x].right = p
        nodes^[p].left = middle
    }
    nodes^[p].parent = x
    if middle >= 0 do nodes^[middle].parent = p
    pull(nodes, p)
    pull(nodes, x)
}
splay :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, x: int) {
    stack: [MAX_N]int
    count := 0
    y := x
    stack[count] = y
    count += 1
    for !is_aux_root(nodes, y) {
        y = nodes^[y].parent
        stack[count] = y
        count += 1
    }
    for count > 0 {
        count -= 1
        push(nodes, stack[count])
    }
    for !is_aux_root(nodes, x) {
        p := nodes^[x].parent
        if !is_aux_root(nodes, p) {
            g := nodes^[p].parent
            zigzig := (nodes^[p].left == x) == (nodes^[g].left == p)
            rotate(nodes, if zigzig do p else x)
        }
        rotate(nodes, x)
    }
}
access :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, x: int) {
    last := -1
    y := x
    for y >= 0 {
        splay(nodes, y)
        old_right := nodes^[y].right
        nodes^[y].virtual_sum += node_sum(nodes, old_right) - node_sum(nodes, last)
        nodes^[y].right = last
        if last >= 0 do nodes^[last].parent = y
        pull(nodes, y)
        last = y
        y = nodes^[y].parent
    }
    splay(nodes, x)
}
make_root :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, x: int) {
    access(nodes, x)
    toggle_reverse(nodes, x)
}
find_root :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, x: int) -> int {
    access(nodes, x)
    push(nodes, x)
    root := x
    for nodes^[root].left >= 0 {
        root = nodes^[root].left
        push(nodes, root)
    }
    splay(nodes, root)
    return root
}
link_nodes :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, u, v: int) -> bool {
    if u == v do return false
    make_root(nodes, u)
    if find_root(nodes, v) == u do return false
    access(nodes, v)
    nodes^[u].parent = v
    nodes^[v].virtual_sum += nodes^[u].sum
    pull(nodes, v)
    return true
}
cut_nodes :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, u, v: int) -> bool {
    if u == v do return false
    make_root(nodes, u)
    access(nodes, v)
    if nodes^[v].left != u || nodes^[u].right >= 0 do return false
    nodes^[v].left = -1
    nodes^[u].parent = -1
    pull(nodes, v)
    return true
}
subtree_side_sum :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, vertex, parent: int) -> i64 {
    make_root(nodes, parent)
    access(nodes, vertex)
    if nodes^[vertex].left != parent || nodes^[parent].right >= 0 do return -1
    return nodes^[vertex].value + nodes^[vertex].virtual_sum
}
put_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := transmute(u64)value
    for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> (8 * byte)) }
}

@(export)
dynamic_tree_vertex_add_subtree_sum :: proc "c" (input: [^]i64, input_length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 3 || input_length > MAX_INPUT do return -1
    n_value, q_value := input[0], input[1]
    if n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q do return -1
    n, q := int(n_value), int(q_value)
    if int(input_length) != 3 * n + 5 * q do return -1
    for i := 0; i < n; i += 1 {
        if input[2 + i] < 0 || input[2 + i] > MAX_VALUE do return -1
    }
    edge_start := 2 + n
    operation_start := edge_start + 2 * (n - 1)
    for i := 0; i < n - 1; i += 1 {
        u, v := input[edge_start + 2 * i], input[edge_start + 2 * i + 1]
        if u < 0 || u >= n_value || v < 0 || v >= n_value || u == v do return -1
    }
    for i := 0; i < q; i += 1 {
        at := operation_start + 5 * i
        kind, a, b, c, d := input[at], input[at + 1], input[at + 2], input[at + 3], input[at + 4]
        if kind == 0 {
            if a < 0 || a >= n_value || b < 0 || b >= n_value || c < 0 || c >= n_value || d < 0 || d >= n_value || a == b || c == d do return -1
        } else if kind == 1 {
            if a < 0 || a >= n_value || b < 0 || b > MAX_VALUE || c != 0 || d != 0 do return -1
        } else if kind == 2 {
            if a < 0 || a >= n_value || b < 0 || b >= n_value || c != 0 || d != 0 do return -1
        } else do return -1
    }
    nodes: [MAX_N]Lct_Node
    for i := 0; i < n; i += 1 {
        nodes[i].left = -1
        nodes[i].right = -1
        nodes[i].parent = -1
        nodes[i].value = input[2 + i]
        nodes[i].sum = nodes[i].value
    }
    for i := 0; i < n - 1; i += 1 {
        if !link_nodes(&nodes, int(input[edge_start + 2 * i]), int(input[edge_start + 2 * i + 1])) do return -1
    }
    answers: [MAX_Q]i64
    answer_count := 0
    for i := 0; i < q; i += 1 {
        at := operation_start + 5 * i
        kind, a, b := int(input[at]), int(input[at + 1]), int(input[at + 2])
        if kind == 0 {
            c, d := int(input[at + 3]), int(input[at + 4])
            if !cut_nodes(&nodes, a, b) || !link_nodes(&nodes, c, d) do return -1
        } else if kind == 1 {
            access(&nodes, a)
            nodes[a].value += i64(b)
            pull(&nodes, a)
        } else {
            answer := subtree_side_sum(&nodes, a, b)
            if answer < 0 do return -1
            answers[answer_count] = answer
            answer_count += 1
        }
    }
    output_bytes := 8 * answer_count
    if output_bytes > 0 && (output == nil || int(output_capacity) < output_bytes) do return -2
    for i := 0; i < answer_count; i += 1 { put_i64(output, i * 8, answers[i]) }
    return i64(output_bytes)
}
