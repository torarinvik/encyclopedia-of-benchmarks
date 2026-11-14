module xor_leaf_tree_traversal

@[export: 'xor_leaf_tree_traversal']
pub fn xor_leaf_tree_traversal(input &i64, length usize, output &u8, capacity usize) i64 {
    if unsafe { input == nil } || length < 2 { return -1 }
    nv := unsafe { input[0] }
    if nv < 1 || nv > 64 { return -1 }
    n := int(nv)
    rv := unsafe { input[1] }
    if rv < 0 || rv >= nv || length != usize(2*n) { return -1 }
    root := int(rv)
    mut degree := [64]int{}
    mut edge_xor := [64]int{}
    mut parents := [64]int{}
    mut dsu := [64]int{}
    mut ranks := [64]int{}
    mut order := [64]int{}
    mut a := [63]int{}
    mut b := [63]int{}
    for i in 0 .. n { dsu[i] = i; parents[i] = -1 }
    for e in 0 .. n-1 {
        ur := unsafe { input[2+2*e] }
        vr := unsafe { input[3+2*e] }
        if ur < 0 || ur >= nv || vr < 0 || vr >= nv || ur == vr { return -1 }
        u := int(ur)
        v := int(vr)
        mut x := u
        mut y := v
        for dsu[x] != x { dsu[x] = dsu[dsu[x]]; x = dsu[x] }
        for dsu[y] != y { dsu[y] = dsu[dsu[y]]; y = dsu[y] }
        if x == y { return -1 }
        if ranks[x] < ranks[y] { dsu[x] = y } else {
            dsu[y] = x
            if ranks[x] == ranks[y] { ranks[x]++ }
        }
        a[e] = u; b[e] = v; degree[u]++; degree[v]++
        edge_xor[u] ^= e; edge_xor[v] ^= e
    }
    degree[root] = 0
    mut used := 0
    for start in 0 .. n {
        mut v := start
        for degree[v] == 1 {
            e := edge_xor[v]
            next := a[e] ^ b[e] ^ v
            parents[v] = e; order[used] = v; used++
            degree[v] = 0; degree[next]--; edge_xor[next] ^= e; v = next
        }
    }
    order[used] = root; used++
    if used != n { return -1 }
    if unsafe { output == nil } || capacity < usize(16*n) { return -2 }
    for i in 0 .. 2*n {
        value := if i < n { i64(parents[i]) } else { i64(order[i-n]) }
        for byte in 0 .. 8 {
            unsafe { output[8*i+byte] = u8((value >> (8*byte)) & 255) }
        }
    }
    return i64(16*n)
}
