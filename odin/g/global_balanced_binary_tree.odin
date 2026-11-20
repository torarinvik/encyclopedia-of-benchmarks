package global_balanced_binary_tree

import "core:c"

MAX_N :: 64
MAX_PARSEABLE_LENGTH :: 65

gbst_build_interval :: proc "contextless" (lo, hi: int, path, prefix: []int,
    gbst_parent, left_child, right_child, local_size: []int) -> int {
    total_weight := prefix[hi] - prefix[lo]
    low, high := lo, hi
    for high - low > 1 {
        middle := (low + high) / 2
        if 2 * (prefix[middle] - prefix[lo]) <= total_weight {
            low = middle
        } else {
            high = middle
        }
    }
    pivot := low
    node := path[pivot]
    local_size[node] = hi - lo
    if lo < pivot {
        child := gbst_build_interval(lo, pivot, path, prefix,
            gbst_parent, left_child, right_child, local_size)
        left_child[node] = child
        gbst_parent[child] = node
    }
    if pivot + 1 < hi {
        child := gbst_build_interval(pivot + 1, hi, path, prefix,
            gbst_parent, left_child, right_child, local_size)
        right_child[node] = child
        gbst_parent[child] = node
    }
    return node
}

@(export)
global_balanced_binary_tree :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > MAX_PARSEABLE_LENGTH do return -1
    n_value := input[0]
    if n_value < 1 || n_value > MAX_N do return -1
    if length != c.size_t(n_value) do return -1
    n := int(n_value)

    parent: [MAX_N]int
    subtree_size: [MAX_N]int
    heavy_child: [MAX_N]int
    gbst_parent: [MAX_N]int
    left_child: [MAX_N]int
    right_child: [MAX_N]int
    local_size: [MAX_N]int
    path: [MAX_N]int
    prefix: [MAX_N + 1]int
    for vertex in 0 .. n {
        parent[vertex] = -1
        subtree_size[vertex] = 1
        heavy_child[vertex] = -1
        gbst_parent[vertex] = -1
        left_child[vertex] = -1
        right_child[vertex] = -1
        local_size[vertex] = 0
    }
    for vertex in 1 .. n {
        p := input[vertex]
        if p < 0 || p >= i64(vertex) do return -1
        parent[vertex] = int(p)
    }

    cursor := n
    for cursor > 1 {
        cursor -= 1
        subtree_size[parent[cursor]] += subtree_size[cursor]
    }
    for vertex in 1 .. n {
        p := parent[vertex]
        current := heavy_child[p]
        if current < 0 || subtree_size[vertex] > subtree_size[current] {
            heavy_child[p] = vertex
        }
    }

    for head in 0 .. n {
        is_head := true
        if head > 0 do is_head = heavy_child[parent[head]] != head
        if !is_head do continue
        path_length := 0
        vertex := head
        prefix[0] = 0
        for vertex < n {
            child := heavy_child[vertex]
            weight := subtree_size[vertex]
            if child >= 0 do weight -= subtree_size[child]
            path[path_length] = vertex
            prefix[path_length + 1] = prefix[path_length] + weight
            path_length += 1
            if child < 0 do break
            vertex = child
        }
        root := gbst_build_interval(0, path_length, path[:], prefix[:],
            gbst_parent[:], left_child[:], right_child[:], local_size[:])
        gbst_parent[root] = -1
        if head > 0 do gbst_parent[root] = parent[head]
    }

    checksum: i64 = 0
    for vertex in 0 .. n {
        record := i64(gbst_parent[vertex] + 1)
            + 65 * i64(left_child[vertex] + 1)
            + 4225 * i64(right_child[vertex] + 1)
            + 274625 * i64(local_size[vertex])
        checksum += i64(vertex + 1) * record
    }
    return checksum
}
