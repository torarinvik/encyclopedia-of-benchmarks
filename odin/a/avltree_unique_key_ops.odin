package avltree_unique_key_ops

import "core:c"

MAX_NODES :: 128
MAX_OPS :: 128
Node :: struct { key: i64, left, right, height: int }

height :: proc "contextless" (nodes: [^]Node, index: int) -> int {
    return if index < 0 then 0 else nodes[index].height
}
update_height :: proc "contextless" (nodes: [^]Node, index: int) {
    left_height := height(nodes, nodes[index].left)
    right_height := height(nodes, nodes[index].right)
    nodes[index].height = 1 + max(left_height, right_height)
}
rotate_right :: proc "contextless" (nodes: [^]Node, root: int) -> int {
    pivot := nodes[root].left
    middle := nodes[pivot].right
    nodes[pivot].right = root
    nodes[root].left = middle
    update_height(nodes, root)
    update_height(nodes, pivot)
    return pivot
}
rotate_left :: proc "contextless" (nodes: [^]Node, root: int) -> int {
    pivot := nodes[root].right
    middle := nodes[pivot].left
    nodes[pivot].left = root
    nodes[root].right = middle
    update_height(nodes, root)
    update_height(nodes, pivot)
    return pivot
}
rebalance :: proc "contextless" (nodes: [^]Node, root: int) -> int {
    if root < 0 do return root
    update_height(nodes, root)
    balance := height(nodes, nodes[root].left) - height(nodes, nodes[root].right)
    if balance > 1 {
        left := nodes[root].left
        if height(nodes, nodes[left].right) > height(nodes, nodes[left].left) do nodes[root].left = rotate_left(nodes, left)
        return rotate_right(nodes, root)
    }
    if balance < -1 {
        right := nodes[root].right
        if height(nodes, nodes[right].left) > height(nodes, nodes[right].right) do nodes[root].right = rotate_right(nodes, right)
        return rotate_left(nodes, root)
    }
    return root
}
insert_node :: proc "contextless" (nodes: [^]Node, root: int, key: i64, next: ^int) -> int {
    if root < 0 {
        index := next^
        next^ += 1
        nodes[index] = Node{key, -1, -1, 1}
        return index
    }
    if key < nodes[root].key do nodes[root].left = insert_node(nodes, nodes[root].left, key, next)
    else do nodes[root].right = insert_node(nodes, nodes[root].right, key, next)
    return rebalance(nodes, root)
}
contains :: proc "contextless" (nodes: [^]Node, root_input: int, key: i64) -> bool {
    root := root_input
    for root >= 0 {
        if nodes[root].key == key do return true
        root = if key < nodes[root].key then nodes[root].left else nodes[root].right
    }
    return false
}
maximum_node :: proc "contextless" (nodes: [^]Node, root_input: int) -> int {
    root := root_input
    for nodes[root].right >= 0 do root = nodes[root].right
    return root
}
delete_node :: proc "contextless" (nodes: [^]Node, root: int, key: i64) -> int {
    if key < nodes[root].key do nodes[root].left = delete_node(nodes, nodes[root].left, key)
    else if key > nodes[root].key do nodes[root].right = delete_node(nodes, nodes[root].right, key)
    else {
        if nodes[root].left < 0 do return nodes[root].right
        if nodes[root].right < 0 do return nodes[root].left
        predecessor := maximum_node(nodes, nodes[root].left)
        nodes[root].key = nodes[predecessor].key
        nodes[root].left = delete_node(nodes, nodes[root].left, nodes[predecessor].key)
    }
    return rebalance(nodes, root)
}
put_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> u64(8 * byte)) }
}

@(export)
avltree_unique_key_ops :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 do return -1
    operation_count_value := input[0]
    if operation_count_value < 0 || operation_count_value > MAX_OPS || int(length) != 1 + 2 * int(operation_count_value) do return -1
    operation_count := int(operation_count_value)
    active: [MAX_NODES]i64
    active_count, search_count := 0, 0
    for index := 0; index < operation_count; index += 1 {
        operation, key := input[1 + 2 * index], input[2 + 2 * index]
        if operation < 0 || operation > 2 || key < -1000000 || key > 1000000 do return -1
        found := -1
        for i := 0; i < active_count; i += 1 { if active[i] == key { found = i; break } }
        if operation == 0 {
            if found >= 0 || active_count >= MAX_NODES do return -1
            active[active_count] = key
            active_count += 1
        } else if operation == 1 {
            search_count += 1
        } else {
            if found < 0 do return -1
            for i := found + 1; i < active_count; i += 1 { active[i - 1] = active[i] }
            active_count -= 1
        }
    }
    nodes: [MAX_NODES]Node
    for i := 0; i < MAX_NODES; i += 1 { nodes[i].left = -1; nodes[i].right = -1 }
    root, next := -1, 0
    results: [MAX_OPS]i64
    result_count := 0
    for index := 0; index < operation_count; index += 1 {
        operation, key := input[1 + 2 * index], input[2 + 2 * index]
        if operation == 0 do root = insert_node(&nodes[0], root, key, &next)
        else if operation == 1 {
            results[result_count] = if contains(&nodes[0], root, key) then 1 else 0
            result_count += 1
        } else do root = delete_node(&nodes[0], root, key)
    }
    bytes := (2 + active_count + search_count) * 8
    if output == nil || int(capacity) < bytes do return -2
    put_i64(output, 0, i64(active_count))
    stack: [MAX_NODES]int
    top, current, out := 0, root, 1
    for current >= 0 || top > 0 {
        for current >= 0 { stack[top] = current; top += 1; current = nodes[current].left }
        top -= 1
        current = stack[top]
        put_i64(output, out * 8, nodes[current].key)
        out += 1
        current = nodes[current].right
    }
    put_i64(output, out * 8, i64(search_count))
    out += 1
    for i := 0; i < search_count; i += 1 { put_i64(output, out * 8, results[i]); out += 1 }
    return i64(bytes)
}
