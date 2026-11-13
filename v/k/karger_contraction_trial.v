fn karger_root(parent []int, vertex int) int {
    mut current := vertex
    for parent[current] != current { current = parent[current] }
    return current
}

@[export: 'karger_contraction_trial']
pub fn karger_contraction_trial(input &i64, length usize) i64 {
    unsafe {
        if input == nil || length < 2 || length > 57 { return -1 }
        if input[0] < 2 || input[0] > 8 || input[1] < 1 || input[1] > 24 { return -1 }
        n := int(input[0])
        m := int(input[1])
        if length != usize(2 + 2 * m + n - 2) { return -1 }
        mut u := []int{len: m}
        mut v := []int{len: m}
        mut parent := []int{len: n}
        for i in 0 .. n { parent[i] = i }
        for i in 0 .. m {
            a := input[2 + 2 * i]
            b := input[3 + 2 * i]
            if a < 0 || b < 0 || a >= i64(n) || b >= i64(n) || a == b { return -1 }
            u[i] = int(a)
            v[i] = int(b)
            left := karger_root(parent, u[i])
            right := karger_root(parent, v[i])
            parent[left] = right
        }
        initial := karger_root(parent, 0)
        for i in 1 .. n { if karger_root(parent, i) != initial { return -1 } }
        for i in 0 .. n { parent[i] = i }
        for step in 0 .. (n - 2) {
            mut live := 0
            for i in 0 .. m { if karger_root(parent, u[i]) != karger_root(parent, v[i]) { live++ } }
            mut rank := input[2 + 2 * m + step]
            if rank < 0 || rank >= i64(live) { return -1 }
            for i in 0 .. m {
                left := karger_root(parent, u[i])
                right := karger_root(parent, v[i])
                if left == right { continue }
                if rank == 0 { parent[left] = right; break }
                rank--
            }
        }
        mut cut := 0
        for i in 0 .. m { if karger_root(parent, u[i]) != karger_root(parent, v[i]) { cut++ } }
        return i64(cut)
    }
}
