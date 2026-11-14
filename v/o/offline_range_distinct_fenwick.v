fn ordf_add(mut tree [65]i64, n int, position int, delta i64) {
    mut i := position+1
    for i <= n { tree[i] += delta; i += i & -i }
}
fn ordf_prefix(tree [65]i64, end int) i64 {
    mut i := end
    mut total := i64(0)
    for i > 0 { total += tree[i]; i &= i-1 }
    return total
}

@[export: 'offline_range_distinct_fenwick']
pub fn offline_range_distinct_fenwick(input &i64, length usize) i64 {
    if length < 3 || length > 195 { return -1 }
    unsafe {
        if input == nil { return -1 }
        nr, qr := input[0], input[1]
        if nr < 1 || nr > 64 || qr < 0 || qr > 64 { return -1 }
        n, q := int(nr), int(qr)
        if length != usize(2+n+2*q) { return -1 }
        for i in 0 .. n { if input[2+i] < 0 || input[2+i] > 255 { return -1 } }
        mut head := [65]int{}
        mut next := [64]int{}
        mut last := [256]int{}
        mut tree := [65]i64{}
        for i in 0 .. 65 { head[i] = -1 }
        for i in 0 .. 256 { last[i] = -1 }
        for i in 0 .. q {
            left, right := input[2+n+2*i], input[3+n+2*i]
            if left < 0 || left > right || right > nr { return -1 }
            next[i] = head[int(right)]; head[int(right)] = i
        }
        mut result := i64(0)
        for right in 0 .. n+1 {
            if right > 0 {
                value := int(input[1+right])
                if last[value] >= 0 { ordf_add(mut tree, n, last[value], -1) }
                ordf_add(mut tree, n, right-1, 1); last[value] = right-1
            }
            mut query := head[right]
            for query >= 0 {
                left := int(input[2+n+2*query])
                result += i64(query+1)*(ordf_prefix(tree,right)-ordf_prefix(tree,left))
                query = next[query]
            }
        }
        return result
    }
}
