// Uncompiled minimum tree path-partition draft.
@[export: 'tree_minimum_path_partition']
pub fn tree_minimum_path_partition(input &i64, length usize) i64 {
    if length < 1 || length > 65 { return -1 }
    unsafe {
        if input == nil { return -1 }
        nv := input[0]
        if nv < 1 || nv > 64 || length != usize(nv) { return -1 }
        n := int(nv)
        for v in 1 .. n { if input[v] < 0 || input[v] >= i64(v) { return -1 } }
        mut base := [64]i64{}
        mut first := [64]i64{}
        mut second := [64]i64{}
        mut v := n-1
        for v > 0 {
            p := int(input[v])
            best := base[v] + first[v] + second[v]
            gain := 1 + base[v] + first[v] - best
            base[p] += best
            if gain > first[p] { second[p] = first[p]; first[p] = gain }
            else if gain > second[p] { second[p] = gain }
            v--
        }
        return nv - base[0] - first[0] - second[0]
    }
}
