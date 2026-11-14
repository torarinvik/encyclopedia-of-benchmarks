@[export: 'incremental_minimum_spanning_forest']
pub fn incremental_minimum_spanning_forest(input &i64, length usize, output &u8, capacity usize) i64 {
    unsafe {
        if input == nil || length < 2 || length > 98 { return -1 }
        n64 := input[0]
        m64 := input[1]
        if n64 < 1 || n64 > 16 || m64 < 1 || m64 > 32 || length != usize(2 + 3*m64) { return -1 }
        m := int(m64)
        for i in 0 .. m {
            u := input[2+3*i]
            v := input[3+3*i]
            w := input[4+3*i]
            if u < 0 || u >= n64 || v < 0 || v >= n64 || w < 1 || w > 1000000 { return -1 }
            for j in 0 .. i { if input[4+3*j] == w { return -1 } }
        }
        mut active := [32]bool{}
        mut answers := [32]i64{}
        for edge in 0 .. m {
            start := int(input[2+3*edge])
            target := int(input[3+3*edge])
            if start == target { answers[edge] = i64(edge); continue }
            mut parent := [16]int{init: -1}
            mut parent_edge := [16]int{}
            mut queue := [16]int{}
            mut head := 0
            mut tail := 1
            queue[0] = start
            parent[start] = start
            for head < tail {
                vertex := queue[head]
                head++
                for i in 0 .. edge {
                    if !active[i] { continue }
                    u := int(input[2+3*i])
                    v := int(input[3+3*i])
                    mut neighbor := -1
                    if u == vertex { neighbor = v } else if v == vertex { neighbor = u }
                    if neighbor >= 0 && parent[neighbor] < 0 {
                        parent[neighbor] = vertex
                        parent_edge[neighbor] = i
                        queue[tail] = neighbor
                        tail++
                    }
                }
            }
            if parent[target] < 0 { active[edge] = true; answers[edge] = -1; continue }
            mut node := target
            mut heaviest := parent_edge[node]
            for node != start {
                i := parent_edge[node]
                if input[4+3*i] > input[4+3*heaviest] { heaviest = i }
                node = parent[node]
            }
            if input[4+3*edge] < input[4+3*heaviest] {
                active[heaviest] = false
                active[edge] = true
                answers[edge] = i64(heaviest)
            } else { answers[edge] = i64(edge) }
        }
        bytes := 8*m
        if output == nil || capacity < usize(bytes) { return -2 }
        for i in 0 .. m {
            bits := u64(answers[i])
            for b in 0 .. 8 { output[8*i+b] = u8((bits >> (8*b)) & 255) }
        }
        return i64(bytes)
    }
}
