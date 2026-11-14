module dynamic_range_majority

struct Summary { value i64; count int }
fn merge(a Summary, b Summary) Summary {
    if a.count == 0 { return b }
    if b.count == 0 { return a }
    if a.value == b.value { return Summary{a.value,a.count+b.count} }
    if a.count >= b.count { return Summary{a.value,a.count-b.count} }
    return Summary{b.value,b.count-a.count}
}
fn slot(value i64, mut names [128]i64, mut size int) int {
    for i in 0 .. size { if names[i] == value { return i } }
    index := size; names[index] = value; size++; return index
}
fn prefix(pos int) u64 {
    if pos == 64 { return ~u64(0) }
    return (u64(1) << pos)-1
}
@[export: 'dynamic_range_majority']
fn dynamic_range_majority(input &i64, length usize, output &u8, capacity usize) i64 {
    unsafe {
        if isnil(input) || length < 2 || length > 258 { return -1 }
        if input[0] < 1 || input[0] > 64 || input[1] < 1 || input[1] > 64 { return -1 }
        n := int(input[0]); q := int(input[1])
        if length != usize(2+n+3*q) { return -1 }
        for i in 0 .. n { if input[2+i] < 0 || input[2+i] > 1000000000 { return -1 } }
        mut queries := 0
        for i in 0 .. q {
            b := 2+n+3*i
            if input[b] == 0 {
                if input[b+1] < 0 || input[b+1] >= n || input[b+2] < 0 || input[b+2] > 1000000000 { return -1 }
            } else if input[b] == 1 {
                if input[b+1] < 0 || input[b+1] >= input[b+2] || input[b+2] > n { return -1 }
                queries++
            } else { return -1 }
        }
        if queries == 0 { return -1 }
        if isnil(output) || capacity < usize(8*queries) { return -2 }
        mut tree := [128]Summary{}
        mut names := [128]i64{}
        mut masks := [128]u64{}
        mut data := [64]i64{}
        mut distinct := 0
        for i in 0 .. n {
            data[i] = input[2+i]; tree[64+i] = Summary{data[i],1}
            s := slot(data[i],mut names,mut distinct); masks[s] |= u64(1) << i
        }
        mut node := 63
        for node > 0 { tree[node] = merge(tree[2*node],tree[2*node+1]); node-- }
        mut written := 0
        for i in 0 .. q {
            b := 2+n+3*i
            if input[b] == 0 {
                p := int(input[b+1]); value := input[b+2]
                old := slot(data[p],mut names,mut distinct); fresh := slot(value,mut names,mut distinct)
                masks[old] &= ~(u64(1) << p); masks[fresh] |= u64(1) << p
                data[p] = value; node = 64+p; tree[node] = Summary{value,1}
                for node > 1 { node /= 2; tree[node] = merge(tree[2*node],tree[2*node+1]) }
            } else {
                lo := int(input[b+1]); hi := int(input[b+2])
                mut l := lo+64; mut r := hi+64
                mut a := Summary{}; mut z := Summary{}
                for l < r {
                    if l & 1 != 0 { a = merge(a,tree[l]); l++ }
                    if r & 1 != 0 { r--; z = merge(tree[r],z) }
                    l /= 2; r /= 2
                }
                candidate := merge(a,z); mut answer := i64(-1)
                if candidate.count > 0 {
                    s := slot(candidate.value,mut names,mut distinct)
                    mut bits := masks[s] & (prefix(hi)^prefix(lo)); mut count := 0
                    for bits != 0 { bits &= bits-1; count++ }
                    if 2*count > hi-lo { answer = candidate.value }
                }
                for byte in 0 .. 8 {
                    output[8*written+byte] = if answer < 0 { u8(255) } else { u8((answer >> (8*byte)) & 255) }
                }
                written++
            }
        }
        return i64(8*written)
    }
}
