package splay_tree

import "core:c"

MAX_OPS :: 64
MAX_KEYS :: 32
MAX_INPUT :: 130
MAX_OUTPUT :: 784

Node :: struct { key: i32, left: i32, right: i32 }

rotate_right :: proc(nodes: [^]Node, root: i32) -> i32 {
    child := nodes[root].left
    nodes[root].left = nodes[child].right
    nodes[child].right = root
    return child
}
rotate_left :: proc(nodes: [^]Node, root: i32) -> i32 {
    child := nodes[root].right
    nodes[root].right = nodes[child].left
    nodes[child].left = root
    return child
}
splay :: proc(nodes: [^]Node, root: i32, key: i32) -> i32 {
    if root < 0 || nodes[root].key == key do return root
    if key < nodes[root].key {
        left := nodes[root].left
        if left < 0 do return root
        if key < nodes[left].key {
            nodes[left].left = splay(nodes, nodes[left].left, key)
            root = rotate_right(nodes, root)
        } else if key > nodes[left].key {
            nodes[left].right = splay(nodes, nodes[left].right, key)
            if nodes[left].right >= 0 do nodes[root].left = rotate_left(nodes, left)
        }
        if nodes[root].left < 0 do return root
        return rotate_right(nodes, root)
    }
    right := nodes[root].right
    if right < 0 do return root
    if key > nodes[right].key {
        nodes[right].right = splay(nodes, nodes[right].right, key)
        root = rotate_left(nodes, root)
    } else if key < nodes[right].key {
        nodes[right].left = splay(nodes, nodes[right].left, key)
        if nodes[right].left >= 0 do nodes[root].right = rotate_right(nodes, right)
    }
    if nodes[root].right < 0 do return root
    return rotate_left(nodes, root)
}
inorder :: proc(nodes: [^]Node, root: i32, keys: [^]i64, count: ^int) {
    if root < 0 do return
    inorder(nodes, nodes[root].left, keys, count)
    keys[count^] = i64(nodes[root].key)
    count^ += 1
    inorder(nodes, nodes[root].right, keys, count)
}
write_word :: proc(out: [^]u8, offset: ^int, word: i64) {
    bits := u64(word)
    for shift in 0..<8 {
        out[offset^] = u8((bits >> (8 * shift)) & 0xff)
        offset^ += 1
    }
}

@(export)
splay_tree :: proc "c" (input: [^]i64, input_length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || input_length == 0 || input_length > MAX_INPUT || input[0] < 0 || input[0] > MAX_OPS do return -1
    op_count := int(input[0])
    if input_length != c.size_t(1 + 2 * op_count) do return -1
    ops: [MAX_OPS]i64
    keys: [MAX_OPS]i64
    tags: [MAX_OPS]i64
    live: [MAX_KEYS]i64
    live_count, offset := 0, 1
    for i in 0..<op_count {
        op, key := input[offset], input[offset+1]
        offset += 2
        if (op != 0 && op != 1 && op != 2) || key < -2147483648 || key > 2147483647 do return -1
        ops[i] = op; keys[i] = key
        found := live_count
        for j in 0..<live_count { if live[j] == key { found = j; break } }
        if op == 0 {
            if found < live_count || live_count == MAX_KEYS do return -1
            live[live_count] = key; live_count += 1
        } else if op == 2 {
            if live_count == 0 do return -1
            if found < live_count { live_count -= 1; live[found] = live[live_count] }
        }
    }
    nodes: [MAX_OPS]Node
    node_count := 0
    root: i32 = -1
    for i in 0..<op_count {
        key := i32(keys[i])
        if ops[i] == 0 {
            if root < 0 {
                nodes[node_count] = Node{key, -1, -1}; root = i32(node_count); node_count += 1
            } else {
                root = splay(&nodes[0], root, key)
                nodes[node_count] = Node{key, -1, -1}; fresh := i32(node_count); node_count += 1
                if key < nodes[root].key { nodes[fresh].left = nodes[root].left; nodes[fresh].right = root; nodes[root].left = -1 }
                else { nodes[fresh].right = nodes[root].right; nodes[fresh].left = root; nodes[root].right = -1 }
                root = fresh
            }
            tags[i] = -2
        } else if ops[i] == 1 {
            root = splay(&nodes[0], root, key)
            tags[i] = 0; if root >= 0 && nodes[root].key == key do tags[i] = 1
        } else {
            root = splay(&nodes[0], root, key); tags[i] = -3
            if nodes[root].key == key {
                left, right := nodes[root].left, nodes[root].right
                if left < 0 do root = right
                else { root = splay(&nodes[0], left, key); nodes[root].right = right }
            }
        }
    }
    final_keys: [MAX_KEYS]i64
    final_count := 0
    inorder(&nodes[0], root, &final_keys[0], &final_count)
    staged: [MAX_OUTPUT]u8
    written := 0
    write_word(&staged[0], &written, i64(op_count))
    for i in 0..<op_count { write_word(&staged[0], &written, tags[i]) }
    write_word(&staged[0], &written, i64(final_count))
    for i in 0..<final_count { write_word(&staged[0], &written, final_keys[i]) }
    if output == nil || capacity < c.size_t(written) do return -2
    for i in 0..<written { output[i] = staged[i] }
    return i64(written)
}
