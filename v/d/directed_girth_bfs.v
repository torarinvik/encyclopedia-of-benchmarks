module directed_girth_bfs

@[export: 'directed_girth_bfs']
pub fn directed_girth_bfs(input &i64, length usize) i64 {
    unsafe {
        if input == nil || length < 2 || length > 131 { return -1 }
        if input[0] < 1 || input[0] > 16 || input[1] < 0 || input[1] > 64 { return -1 }
        n := int(input[0])
        m := int(input[1])
        if length != usize(2+2*m) { return -1 }
        mut outgoing := [16]u32{}
        for i in 0 .. m {
            u := input[2+2*i]
            v := input[3+2*i]
            if u < 0 || v < 0 || u >= i64(n) || v >= i64(n) { return -1 }
            outgoing[int(u)] |= u32(1) << int(v)
        }
        mut best := 17
        for start in 0 .. n {
            mut distance := [16]int{}
            mut queue := [16]int{}
            for i in 0 .. n { distance[i] = -1 }
            distance[start] = 0
            queue[0] = start
            mut head := 0
            mut tail := 1
            for head < tail {
                u := queue[head]
                head++
                for v in 0 .. n {
                    if outgoing[u] & (u32(1) << v) == 0 { continue }
                    if v == start {
                        if distance[u]+1 < best { best = distance[u]+1 }
                    } else if distance[v] < 0 {
                        distance[v] = distance[u]+1
                        queue[tail] = v
                        tail++
                    }
                }
            }
        }
        if best == 17 { return 0 }
        return i64(best)
    }
}
