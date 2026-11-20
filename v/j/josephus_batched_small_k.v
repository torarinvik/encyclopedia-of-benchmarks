module josephus_batched_small_k

@[export: 'josephus_batched_small_k']
pub fn josephus_batched_small_k(values &i64, length usize) i64 {
    if length != 2 { return -1 }
    unsafe {
        if values == nil { return -1 }
        n0, k := values[0], values[1]
        if n0 < 1 || n0 > 1_000_000 || k < 1 || k > 32 { return -1 }
        if n0 == 1 { return 0 }
        if k == 1 { return n0 - 1 }
        mut frames := [1024]i64{}
        mut depth := 0
        mut n := n0
        for n > 1 {
            if depth == frames.len { return -1 }
            frames[depth] = n
            depth++
            if n < k { n-- } else { n -= n / k }
        }
        mut survivor := i64(0)
        for depth > 0 {
            depth--
            m := frames[depth]
            if m < k { survivor = (survivor + k) % m }
            else {
                survivor -= m % k
                if survivor < 0 { survivor += m } else { survivor += survivor / (k - 1) }
            }
        }
        return survivor
    }
}
