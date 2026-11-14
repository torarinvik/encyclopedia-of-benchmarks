package offline_range_distinct_fenwick

import "core:c"

add :: proc(tree: ^[65]i64, n, position: int, delta: i64) {
    i := position+1
    for i <= n { tree[i] += delta; i += i & -i }
}
prefix :: proc(tree: ^[65]i64, end: int) -> i64 {
    i := end
    sum := i64(0)
    for i > 0 { sum += tree[i]; i &= i-1 }
    return sum
}

@(export)
offline_range_distinct_fenwick :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 3 || length > 195 do return -1
    nr, qr := input[0], input[1]
    if nr < 1 || nr > 64 || qr < 0 || qr > 64 do return -1
    n, q := int(nr), int(qr)
    if length != c.size_t(2+n+2*q) do return -1
    for i := 0; i < n; i += 1 {
        if input[2+i] < 0 || input[2+i] > 255 do return -1
    }
    head: [65]int; next: [64]int; last: [256]int; tree: [65]i64 = {}
    for i := 0; i < 65; i += 1 { head[i] = -1 }
    for i := 0; i < 256; i += 1 { last[i] = -1 }
    for i := 0; i < q; i += 1 {
        left, right := input[2+n+2*i], input[3+n+2*i]
        if left < 0 || left > right || right > nr do return -1
        next[i] = head[int(right)]; head[int(right)] = i
    }
    result := i64(0)
    for right := 0; right <= n; right += 1 {
        if right > 0 {
            value := int(input[1+right])
            if last[value] >= 0 { add(&tree, n, last[value], -1) }
            add(&tree, n, right-1, 1); last[value] = right-1
        }
        query := head[right]
        for query >= 0 {
            left := int(input[2+n+2*query])
            result += i64(query+1)*(prefix(&tree,right)-prefix(&tree,left))
            query = next[query]
        }
    }
    return result
}
