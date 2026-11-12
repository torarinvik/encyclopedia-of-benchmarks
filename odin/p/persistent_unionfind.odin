package persistent_unionfind

import "core:c"

MAX_N :: 64
MAX_Q :: 64
MAX_INPUT_VALUES :: 2 + 4 * MAX_Q

find_root :: proc "contextless" (parent: [^]int, item: int) -> int {
    current := item
    for parent[current] != current {
        current = parent[current]
    }
    return current
}

visit_version :: proc(node: int, kind, u, v: [^]i64,
    first_child, next_sibling: [^]int,
    parent, set_size: [^]int, answer: [^]i64,
    history_child, history_root, history_size: [^]int64, history_count: ^int) {
    saved_history := history_count^
    if node != 0 {
        operation := node - 1
        if kind[operation] == 0 {
            root_u := find_root(parent, int(u[operation]))
            root_v := find_root(parent, int(v[operation]))
            if root_u == root_v {
                history_child[history_count^] = -1
                history_root[history_count^] = -1
                history_size[history_count^] = 0
            } else {
                if set_size[root_u] > set_size[root_v] {
                    temporary := root_u
                    root_u = root_v
                    root_v = temporary
                }
                history_child[history_count^] = int64(root_u)
                history_root[history_count^] = int64(root_v)
                history_size[history_count^] = int64(set_size[root_v])
                parent[root_u] = root_v
                set_size[root_v] += set_size[root_u]
            }
            history_count^ += 1
        } else {
            if find_root(parent, int(u[operation])) == find_root(parent, int(v[operation])) {
                answer[node] = 1
            } else {
                answer[node] = 0
            }
        }
    }
    child := first_child[node]
    for child >= 0 {
        visit_version(child, kind, u, v, first_child, next_sibling, parent,
            set_size, answer, history_child, history_root, history_size, history_count)
        child = next_sibling[child - 1]
    }
    for history_count^ > saved_history {
        history_count^ -= 1
        changed_child := history_child[history_count^]
        if changed_child >= 0 {
            root := int(history_root[history_count^])
            parent[int(changed_child)] = int(changed_child)
            set_size[root] = int(history_size[history_count^])
        }
    }
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits >> u64(8 * byte))
    }
}

@(export)
persistent_unionfind :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 6 || length > MAX_INPUT_VALUES do return -1
    n_value := input[0]
    q_value := input[1]
    if n_value < 1 || n_value > MAX_N || q_value < 1 || q_value > MAX_Q do return -1
    n := int(n_value)
    q := int(q_value)
    if length != c.size_t(2 + 4 * q) do return -1

    kind: [MAX_Q]i64
    u: [MAX_Q]i64
    v: [MAX_Q]i64
    first_child: [MAX_Q + 1]int
    next_sibling: [MAX_Q]int
    answer: [MAX_Q + 1]i64
    for node := 0; node <= q; node += 1 do first_child[node] = -1
    query_count := 0
    for operation := 0; operation < q; operation += 1 {
        offset := 2 + 4 * operation
        kind[operation] = input[offset]
        version := input[offset + 1]
        u[operation] = input[offset + 2]
        v[operation] = input[offset + 3]
        if (kind[operation] != 0 && kind[operation] != 1) || version < -1 ||
           version >= i64(operation) || u[operation] < 0 || u[operation] >= n_value ||
           v[operation] < 0 || v[operation] >= n_value do return -1
        if version >= 0 && kind[int(version)] != 0 do return -1
        if kind[operation] == 1 do query_count += 1
        parent_node := int(version + 1)
        next_sibling[operation] = first_child[parent_node]
        first_child[parent_node] = operation + 1
    }

    required := 8 * query_count
    if output == nil || capacity < c.size_t(required) do return -2
    parent: [MAX_N]int
    set_size: [MAX_N]int
    for item := 0; item < n; item += 1 {
        parent[item] = item
        set_size[item] = 1
    }
    history_child: [MAX_Q]int64
    history_root: [MAX_Q]int64
    history_size: [MAX_Q]int64
    history_count := 0
    visit_version(0, &kind[0], &u[0], &v[0], &first_child[0], &next_sibling[0],
        &parent[0], &set_size[0], &answer[0], &history_child[0],
        &history_root[0], &history_size[0], &history_count)
    written := 0
    for operation := 0; operation < q; operation += 1 {
        if kind[operation] == 1 {
            store_i64_le(output, written, answer[operation + 1])
            written += 8
        }
    }
    return i64(written)
}
