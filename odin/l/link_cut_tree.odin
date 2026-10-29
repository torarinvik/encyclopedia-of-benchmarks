package link_cut_tree

import "core:c"

MAX_N :: 16
MAX_Q :: 64
MAX_INPUT :: 210

Lct_Node :: struct {
    left, right, parent: int,
    reversed: bool,
    value, sum: i64,
}

is_aux_root :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, x: int) -> bool {
    p := nodes^[x].parent
    return p < 0 || (nodes^[p].left != x && nodes^[p].right != x)
}
pull :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, x: int) {
    left_sum: i64 = 0
    right_sum: i64 = 0
    if nodes^[x].left >= 0 do left_sum = nodes^[nodes^[x].left].sum
    if nodes^[x].right >= 0 do right_sum = nodes^[nodes^[x].right].sum
    nodes^[x].sum = nodes^[x].value + left_sum + right_sum
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
    middle := nodes^[x].left
    if !right_child do middle = nodes^[x].right
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
link_nodes :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, u, v: int) -> i64 {
    if u == v do return 0
    make_root(nodes, u)
    if find_root(nodes, v) == u do return 0
    nodes^[u].parent = v
    return 1
}
cut_nodes :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, u, v: int) -> i64 {
    if u == v do return 0
    make_root(nodes, u)
    access(nodes, v)
    if nodes^[v].left != u || nodes^[u].right >= 0 do return 0
    nodes^[v].left = -1
    nodes^[u].parent = -1
    pull(nodes, v)
    return 1
}
path_sum :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, u, v: int) -> i64 {
    make_root(nodes, u)
    if find_root(nodes, v) != u do return -1
    make_root(nodes, u)
    access(nodes, v)
    return nodes^[v].sum
}
put_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := transmute(u64)value
    for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> (8 * byte)) }
}

@(export)
link_cut_tree :: proc "c" (input: [^]i64, input_length: c.size_t,
                            output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 2 || input_length > MAX_INPUT do return -1
    n_value, q_value := input[0], input[1]
    if n_value < 1 || n_value > MAX_N || q_value < 1 || q_value > MAX_Q do return -1
    n, q := int(n_value), int(q_value)
    if int(input_length) != 2 + n + 3 * q do return -1
    for i := 0; i < n; i += 1 {
        if input[2 + i] < 0 || input[2 + i] > 1000000 do return -1
    }
    operations_at := 2 + n
    for i := 0; i < q; i += 1 {
        at := operations_at + 3 * i
        op, u, v := input[at], input[at + 1], input[at + 2]
        if op < 0 || op > 2 || u < 0 || u >= n_value || v < 0 || v >= n_value do return -1
    }
    bytes := 8 * q
    if output == nil || int(output_capacity) < bytes do return -2
    nodes: [MAX_N]Lct_Node
    for i := 0; i < n; i += 1 {
        nodes[i].left = -1
        nodes[i].right = -1
        nodes[i].parent = -1
        nodes[i].value = input[2 + i]
        nodes[i].sum = nodes[i].value
    }
    for i := 0; i < q; i += 1 {
        at := operations_at + 3 * i
        op, u, v := int(input[at]), int(input[at + 1]), int(input[at + 2])
        result: i64
        if op == 0 do result = link_nodes(&nodes, u, v)
        else if op == 1 do result = cut_nodes(&nodes, u, v)
        else do result = path_sum(&nodes, u, v)
        put_i64(output, 8 * i, result)
    }
    return i64(bytes)
}
