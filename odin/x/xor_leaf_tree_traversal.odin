package bench

@(export)
xor_leaf_tree_traversal :: proc "c" (input: [^]i64, length: uint, output: [^]u8, capacity: uint) -> i64 {
    if input == nil || length < 2 || input[0] < 1 || input[0] > 64 { return -1 }
    n := int(input[0])
    if input[1] < 0 || input[1] >= input[0] || length != uint(2*n) { return -1 }
    root := int(input[1])
    degree, edge_xor, parents, dsu, ranks, order: [64]int
    a, b: [63]int
    for i in 0..<n { dsu[i] = i; parents[i] = -1 }
    for e in 0..<n-1 {
        ur, vr := input[2+2*e], input[3+2*e]
        if ur < 0 || ur >= input[0] || vr < 0 || vr >= input[0] || ur == vr { return -1 }
        u, v := int(ur), int(vr)
        x, y := u, v
        for dsu[x] != x { dsu[x] = dsu[dsu[x]]; x = dsu[x] }
        for dsu[y] != y { dsu[y] = dsu[dsu[y]]; y = dsu[y] }
        if x == y { return -1 }
        if ranks[x] < ranks[y] { dsu[x] = y } else {
            dsu[y] = x
            if ranks[x] == ranks[y] { ranks[x] += 1 }
        }
        a[e], b[e] = u, v
        degree[u] += 1; degree[v] += 1
        edge_xor[u] ~= e; edge_xor[v] ~= e
    }
    degree[root] = 0
    used := 0
    for start in 0..<n {
        v := start
        for degree[v] == 1 {
            e := edge_xor[v]
            next := a[e] ~ b[e] ~ v
            parents[v] = e; order[used] = v; used += 1
            degree[v] = 0; degree[next] -= 1; edge_xor[next] ~= e; v = next
        }
    }
    order[used] = root; used += 1
    if used != n { return -1 }
    if output == nil || capacity < uint(16*n) { return -2 }
    for i in 0..<2*n {
        value := i64(0)
        if i < n { value = i64(parents[i]) } else { value = i64(order[i-n]) }
        bits := transmute(u64)value
        for byte in 0..<8 { output[8*i+byte] = u8((bits >> uint(8*byte)) & 255) }
    }
    return i64(16*n)
}
