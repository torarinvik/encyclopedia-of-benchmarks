module kruskal

fn sift_down(mut keys &i64, start_root int, end int) {
    mut root := start_root
    for root < end / 2 {
        mut child := root * 2 + 1
        if child + 1 < end && unsafe { keys[child] < keys[child + 1] } { child++ }
        if unsafe { keys[root] >= keys[child] } { break }
        unsafe { temporary := keys[root]; keys[root] = keys[child]; keys[child] = temporary }
        root = child
    }
}
fn find_root(mut parent &usize, start_node usize) usize {
    mut node := start_node
    for unsafe { parent[node] != node } {
        unsafe { parent[node] = parent[parent[node]]; node = parent[node] }
    }
    return node
}

// Heapsort packed undirected edges, then union their components by rank.
@[export: 'kruskal']
pub fn kruskal(values &i64, length usize) i64 {
    if length < 2 || length > 12290 { return -2 }
    if unsafe { values[0] } < 0 || unsafe { values[0] } > 64 || unsafe { values[1] } < 0 || unsafe { values[1] } > 4096 { return -2 }
    vertices := int(unsafe { values[0] }); edges := int(unsafe { values[1] })
    if length != usize(2 + 3 * edges) || (vertices == 0 && edges != 0) { return -2 }
    if vertices == 0 { return 0 }
    mut keys := [4096]i64{}
    for edge in 0 .. edges {
        mut u := unsafe { values[2 + 3 * edge] }; mut v := unsafe { values[3 + 3 * edge] }; weight := unsafe { values[4 + 3 * edge] }
        if u < 0 || v < 0 || u >= i64(vertices) || v >= i64(vertices) || weight < 0 || weight > 2147483647 { return -2 }
        if u > v { temporary := u; u = v; v = temporary }
        keys[edge] = weight * 4096 + u * 64 + v
    }
    mut start := edges / 2
    for start > 0 { start--; sift_down(mut keys[0], start, edges) }
    mut end := edges
    for end > 1 {
        end--
        temporary := keys[0]; keys[0] = keys[end]; keys[end] = temporary
        sift_down(mut keys[0], 0, end)
    }
    mut parent := [64]usize{}
    mut ranks := [64]usize{}
    for vertex in 0 .. vertices { parent[vertex] = usize(vertex) }
    mut selected := 0
    mut total := i64(0)
    for edge in 0 .. edges {
        if selected + 1 >= vertices { break }
        key := keys[edge]
        u := usize((key % 4096) / 64); v := usize(key % 64)
        mut root_u := find_root(mut parent[0], u); mut root_v := find_root(mut parent[0], v)
        if root_u != root_v {
            total += key / 4096; selected++
            if ranks[root_u] < ranks[root_v] { parent[root_u] = root_v }
            else if ranks[root_u] > ranks[root_v] { parent[root_v] = root_u }
            else { parent[root_v] = root_u; ranks[root_u]++ }
        }
    }
    if selected + 1 == vertices { return total }
    return -1
}
