package range_union_find

import "core:c"

MAX_N :: 32
MAX_Q :: 32
MAX_PARSEABLE_LENGTH :: c.size_t(99)

find_root :: proc "contextless" (parent: ^[MAX_N]i64, vertex_input: int) -> int {
    vertex := vertex_input
    for parent[vertex] >= 0 {
        ancestor := int(parent[vertex])
        if parent[ancestor] >= 0 do parent[vertex] = parent[ancestor]
        vertex = ancestor
    }
    return vertex
}

unite_roots :: proc "contextless" (parent, left, right: ^[MAX_N]i64,
    root_a_input, root_b_input: int) -> int {
    root_a := root_a_input
    root_b := root_b_input
    if parent[root_a] > parent[root_b] {
        temporary := root_a
        root_a = root_b
        root_b = temporary
    }
    parent[root_a] += parent[root_b]
    parent[root_b] = i64(root_a)
    if left[root_b] < left[root_a] do left[root_a] = left[root_b]
    if right[root_b] > right[root_a] do right[root_a] = right[root_b]
    return root_a
}

range_union_find :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || length > MAX_PARSEABLE_LENGTH do return -1
    n_value := values[0]; q_value := values[1]
    if n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q ||
        int(length) != 2 + 3 * int(q_value) do return -1
    n := int(n_value); q := int(q_value)
    for operation := 0; operation < q; operation += 1 {
        offset := 2 + 3 * operation
        opcode := values[offset]; first := values[offset+1]; second := values[offset+2]
        if opcode == 0 { if first < 0 || first > second || second > n_value do return -1 }
        else if opcode == 1 { if first < 0 || first >= n_value || second < 0 || second >= n_value do return -1 }
        else if opcode == 2 { if first < 0 || first >= n_value || second != 0 do return -1 }
        else do return -1
    }
    parent: [MAX_N]i64 = {}
    left: [MAX_N]i64 = {}
    right: [MAX_N]i64 = {}
    for vertex := 0; vertex < n; vertex += 1 {
        parent[vertex] = -1; left[vertex] = i64(vertex); right[vertex] = i64(vertex+1)
    }
    components := n; total := i64(0)
    for operation := 0; operation < q; operation += 1 {
        offset := 2 + 3 * operation
        opcode := values[offset]; first := int(values[offset+1]); second := int(values[offset+2])
        observed := i64(0)
        if opcode == 0 {
            if first < second {
                root := find_root(&parent, first)
                next := int(right[root])
                for next < second {
                    next_root := find_root(&parent, next)
                    if root == next_root do break
                    root = unite_roots(&parent, &left, &right, root, next_root)
                    components -= 1
                    next = int(right[root])
                }
            }
            observed = i64(components)
        } else if opcode == 1 {
            observed = 0
            if find_root(&parent, first) == find_root(&parent, second) do observed = 1
        } else { observed = -parent[find_root(&parent, first)] }
        total += i64(operation + 1) * observed
    }
    return total
}
