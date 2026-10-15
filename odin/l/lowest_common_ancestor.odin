package lowest_common_ancestor

import "core:c"

@(export)
lowest_common_ancestor :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 4 || input[0] < 2 || input[0] > 1023 do return -1
    count := int(input[0])
    if int(length) != 4 + 3 * count do return -1
    for field := 1; field <= 3; field += 1 {
        if input[field] < 0 || input[field] >= i64(count) do return -1
    }
    if input[2] == input[3] do return -1
    root := int(input[1])
    p := int(input[2])
    q := int(input[3])

    parent: [1023]i64 = {}
    stack: [1023]int = {}
    path_p: [1023]int = {}
    path_q: [1023]int = {}
    seen: [1023]bool = {}
    for node := 0; node < count; node += 1 do parent[node] = -1
    for node := 0; node < count; node += 1 {
        offset := 4 + 3 * node
        if input[offset] < -1_000_000_000 || input[offset] > 1_000_000_000 do return -1
        for edge := 1; edge <= 2; edge += 1 {
            child := input[offset + edge]
            if child < -1 || child >= i64(count) do return -1
            if child >= 0 {
                child_index := int(child)
                if parent[child_index] != -1 do return -1
                parent[child_index] = i64(node)
            }
        }
    }
    if parent[root] != -1 do return -1
    for node := 0; node < count; node += 1 {
        if node != root && parent[node] == -1 do return -1
    }

    top := 0
    reached := 0
    stack[top] = root
    top += 1
    for top > 0 {
        top -= 1
        node := stack[top]
        if seen[node] do return -1
        seen[node] = true
        reached += 1
        offset := 4 + 3 * node
        for edge := 1; edge <= 2; edge += 1 {
            child := input[offset + edge]
            if child >= 0 {
                stack[top] = int(child)
                top += 1
            }
        }
    }
    if reached != count do return -1

    depth_p := 0
    depth_q := 0
    current := p
    path_p[depth_p] = current
    depth_p += 1
    for current != root {
        current = int(parent[current])
        path_p[depth_p] = current
        depth_p += 1
    }
    current = q
    path_q[depth_q] = current
    depth_q += 1
    for current != root {
        current = int(parent[current])
        path_q[depth_q] = current
        depth_q += 1
    }
    ancestor: i64 = -1
    for depth_p > 0 && depth_q > 0 {
        if path_p[depth_p - 1] != path_q[depth_q - 1] do break
        ancestor = i64(path_p[depth_p - 1])
        depth_p -= 1
        depth_q -= 1
    }
    return ancestor
}
