struct MstTopPair {
    first i64
    second i64
}

fn mst_merge(a MstTopPair, b MstTopPair) MstTopPair {
    mut first := i64(-1)
    mut second := i64(-1)
    for value in [a.first, a.second, b.first, b.second] {
        if value > first {
            second = first
            first = value
        } else if value < first && value > second {
            second = value
        }
    }
    return MstTopPair{first, second}
}

@[export: 'second_best_mst_binary_lifting']
pub fn second_best_mst_binary_lifting(input &i64, length usize) i64 {
    unsafe {
        if input == nil || length < 2 || length > 63 { return -1 }
        nv := input[0]
        mv := input[1]
        if nv < 1 || nv > 8 || mv < nv - 1 || mv > 20 || length != usize(2 + 3 * mv) { return -1 }
        n := int(nv)
        m := int(mv)
        mut u := [20]int{}
        mut v := [20]int{}
        mut weight := [20]i64{}
        mut order := [20]int{}
        mut seen := [64]bool{}
        for i in 0 .. m {
            a := input[2 + 3 * i]
            b := input[3 + 3 * i]
            w := input[4 + 3 * i]
            if a < 0 || a >= b || b >= nv || w < 0 || w > 1000000 { return -1 }
            pos := int(a * 8 + b)
            if seen[pos] { return -1 }
            seen[pos] = true
            u[i] = int(a)
            v[i] = int(b)
            weight[i] = w
            order[i] = i
        }
        mut sort_index := 1
        for sort_index < m {
            edge := order[sort_index]
            mut j := sort_index
            for j > 0 && weight[order[j - 1]] > weight[edge] {
                order[j] = order[j - 1]
                j--
            }
            order[j] = edge
            sort_index++
        }
        mut parent := [8]int{}
        mut degree := [8]int{}
        mut adjacent := [64]int{}
        mut edge_at := [64]int{}
        mut selected := [20]bool{}
        for i in 0 .. n { parent[i] = i }
        mut count := 0
        mut total := i64(0)
        for i in 0 .. m {
            edge := order[i]
            mut a := u[edge]
            mut b := v[edge]
            for parent[a] != a { a = parent[a] }
            for parent[b] != b { b = parent[b] }
            if a == b { continue }
            parent[a] = b
            selected[edge] = true
            count++
            total += weight[edge]
            pu := u[edge] * 8 + degree[u[edge]]
            pv := v[edge] * 8 + degree[v[edge]]
            adjacent[pu] = v[edge]
            adjacent[pv] = u[edge]
            edge_at[pu] = edge
            edge_at[pv] = edge
            degree[u[edge]]++
            degree[v[edge]]++
        }
        if count != n - 1 { return -1 }
        mut up := [32]int{}
        mut best := [32]MstTopPair{}
        mut depth := [8]int{}
        mut queue := [8]int{}
        for i in 0 .. 32 { best[i] = MstTopPair{-1, -1} }
        for i in 0 .. n { depth[i] = -1 }
        depth[0] = 0
        mut head := 0
        mut tail := 1
        for head < tail {
            vertex := queue[head]
            head++
            for i in 0 .. degree[vertex] {
                pos := vertex * 8 + i
                next := adjacent[pos]
                if depth[next] >= 0 { continue }
                depth[next] = depth[vertex] + 1
                up[next] = vertex
                best[next] = MstTopPair{weight[edge_at[pos]], -1}
                queue[tail] = next
                tail++
            }
        }
        for level in 1 .. 4 {
            for vertex in 0 .. n {
                prev := (level - 1) * 8 + vertex
                other := (level - 1) * 8 + up[prev]
                dest := level * 8 + vertex
                up[dest] = up[other]
                best[dest] = mst_merge(best[prev], best[other])
            }
        }
        mut increase := i64(-1)
        for edge in 0 .. m {
            if selected[edge] { continue }
            mut a := u[edge]
            mut b := v[edge]
            if depth[a] < depth[b] { tmp := a; a = b; b = tmp }
            mut path := MstTopPair{-1, -1}
            difference := depth[a] - depth[b]
            for level in 0 .. 4 {
                if difference & (1 << level) != 0 {
                    pos := level * 8 + a
                    path = mst_merge(path, best[pos])
                    a = up[pos]
                }
            }
            if a != b {
                for level := 3; level >= 0; level-- {
                    pa := level * 8 + a
                    pb := level * 8 + b
                    if up[pa] != up[pb] {
                        path = mst_merge(mst_merge(path, best[pa]), best[pb])
                        a = up[pa]
                        b = up[pb]
                    }
                }
                path = mst_merge(mst_merge(path, best[a]), best[b])
            }
            mut removed := path.second
            if weight[edge] > path.first { removed = path.first }
            if removed >= 0 && removed < weight[edge] {
                delta := weight[edge] - removed
                if increase < 0 || delta < increase { increase = delta }
            }
        }
        if increase < 0 { return 0 }
        return total + increase + 1
    }
}
