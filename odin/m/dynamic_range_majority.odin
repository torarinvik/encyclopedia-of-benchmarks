package dynamic_range_majority
import "core:c"

Summary :: struct { value: i64, count: int }
merge :: proc(a, b: Summary) -> Summary {
    if a.count == 0 { return b }
    if b.count == 0 { return a }
    if a.value == b.value { return Summary{a.value,a.count+b.count} }
    if a.count >= b.count { return Summary{a.value,a.count-b.count} }
    return Summary{b.value,b.count-a.count}
}
slot :: proc(value: i64, names: ^[128]i64, size: ^int) -> int {
    for i := 0; i < size^; i += 1 { if names[i] == value { return i } }
    result := size^; names[result] = value; size^ += 1; return result
}
prefix :: proc(pos: int) -> u64 {
    if pos == 64 { return ~u64(0) }
    return (u64(1) << u64(pos))-1
}
@(export)
dynamic_range_majority :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 258 { return -1 }
    if input[0] < 1 || input[0] > 64 || input[1] < 1 || input[1] > 64 { return -1 }
    n, q := int(input[0]), int(input[1])
    if int(length) != 2+n+3*q { return -1 }
    for i := 0; i < n; i += 1 { if input[2+i] < 0 || input[2+i] > 1000000000 { return -1 } }
    queries := 0
    for i := 0; i < q; i += 1 {
        b := 2+n+3*i
        if input[b] == 0 {
            if input[b+1] < 0 || input[b+1] >= i64(n) || input[b+2] < 0 || input[b+2] > 1000000000 { return -1 }
        } else if input[b] == 1 {
            if input[b+1] < 0 || input[b+1] >= input[b+2] || input[b+2] > i64(n) { return -1 }
            queries += 1
        } else { return -1 }
    }
    if queries == 0 { return -1 }
    if output == nil || capacity < c.size_t(8*queries) { return -2 }
    tree: [128]Summary
    names: [128]i64
    masks: [128]u64
    data: [64]i64
    distinct := 0
    for i := 0; i < n; i += 1 {
        data[i] = input[2+i]; tree[64+i] = Summary{data[i],1}
        s := slot(data[i],&names,&distinct); masks[s] |= u64(1) << u64(i)
    }
    for node := 63; node > 0; node -= 1 { tree[node] = merge(tree[2*node],tree[2*node+1]) }
    written := 0
    for i := 0; i < q; i += 1 {
        b := 2+n+3*i
        if input[b] == 0 {
            p, value := int(input[b+1]), input[b+2]
            old, fresh := slot(data[p],&names,&distinct), slot(value,&names,&distinct)
            masks[old] &= ~(u64(1) << u64(p)); masks[fresh] |= u64(1) << u64(p)
            data[p] = value; node := 64+p; tree[node] = Summary{value,1}
            for node > 1 { node /= 2; tree[node] = merge(tree[2*node],tree[2*node+1]) }
        } else {
            lo, hi := int(input[b+1]), int(input[b+2])
            l, r := lo+64, hi+64
            a, z: Summary
            for l < r {
                if l & 1 != 0 { a = merge(a,tree[l]); l += 1 }
                if r & 1 != 0 { r -= 1; z = merge(tree[r],z) }
                l /= 2; r /= 2
            }
            candidate := merge(a,z); answer: i64 = -1
            if candidate.count > 0 {
                s := slot(candidate.value,&names,&distinct)
                bits := masks[s] & (prefix(hi) ~ prefix(lo)); count := 0
                for bits != 0 { bits &= bits-1; count += 1 }
                if 2*count > hi-lo { answer = candidate.value }
            }
            for byte := 0; byte < 8; byte += 1 {
                if answer < 0 { output[8*written+byte] = 255 }
                else { output[8*written+byte] = u8((answer >> u64(8*byte)) & 255) }
            }
            written += 1
        }
    }
    return i64(8*written)
}
