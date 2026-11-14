module xor_filter_peeling

@[export: 'xor_filter_peeling']
pub fn xor_filter_peeling(input &i64, length usize) i64 {
    if unsafe { input == nil } || length < 3 || length > 259 { return -1 }
    nv := unsafe { input[0] }
    sv := unsafe { input[1] }
    qv := unsafe { input[2] }
    if nv < 0 || nv > 32 || sv < 3 || sv > 96 || qv < 0 || qv > 32 { return -1 }
    n := int(nv)
    slots := int(sv)
    q := int(qv)
    if length != usize(3+4*(n+q)) { return -1 }
    for i in 0 .. n+q {
        at := 3+4*i
        a := unsafe { input[at] }
        b := unsafe { input[at+1] }
        c := unsafe { input[at+2] }
        f := unsafe { input[at+3] }
        if a < 0 || a >= sv || b < 0 || b >= sv || c < 0 || c >= sv || a == b || a == c || b == c || f < 0 || f > 255 { return -1 }
    }
    mut degree := [96]int{}
    mut edge_xor := [96]int{}
    mut queue := [96]int{}
    mut table := [96]int{}
    mut stack_slot := [32]int{}
    mut stack_edge := [32]int{}
    for edge in 0 .. n {
        for j in 0 .. 3 {
            slot := int(unsafe { input[3+4*edge+j] })
            degree[slot]++
            edge_xor[slot] ^= edge
        }
    }
    mut head := 0
    mut tail := 0
    mut used := 0
    for slot in 0 .. slots {
        if degree[slot] == 1 { queue[tail] = slot; tail++ }
    }
    for head < tail {
        slot := queue[head]
        head++
        if degree[slot] != 1 { continue }
        edge := edge_xor[slot]
        stack_slot[used] = slot
        stack_edge[used] = edge
        used++
        for j in 0 .. 3 {
            v := int(unsafe { input[3+4*edge+j] })
            degree[v]--
            edge_xor[v] ^= edge
            if degree[v] == 1 { queue[tail] = v; tail++ }
        }
    }
    if used != n { return -2 }
    for used > 0 {
        used--
        at := 3+4*stack_edge[used]
        a := int(unsafe { input[at] })
        b := int(unsafe { input[at+1] })
        c := int(unsafe { input[at+2] })
        table[stack_slot[used]] = int(unsafe { input[at+3] }) ^ table[a] ^ table[b] ^ table[c]
    }
    mut result := i64(0)
    for i in 0 .. q {
        at := 3+4*(n+i)
        a := int(unsafe { input[at] })
        b := int(unsafe { input[at+1] })
        c := int(unsafe { input[at+2] })
        if (table[a] ^ table[b] ^ table[c]) == int(unsafe { input[at+3] }) { result += i64(i+1) }
    }
    return result
}
