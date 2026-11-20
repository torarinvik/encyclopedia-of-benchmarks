module undirected_cycle_check_bfs

@[export: 'undirected_cycle_check_bfs']
pub fn undirected_cycle_check_bfs(input &i64, length usize) i64 {
    if unsafe { input == nil } || length < 2 || length > 514 { return -1 }
    unsafe {
        if input[0] < 0 || input[0] > 32 || input[1] < 0 || input[1] > 256 { return -1 }
        n := int(input[0]); m := int(input[1])
        if length != usize(2 + 2 * m) { return -1 }
        mut adjacent := [32][32]bool{}
        mut visited := [32]bool{}
        for i in 0 .. m {
            a := input[2 + 2 * i]; b := input[3 + 2 * i]
            if a < 0 || b < 0 || a >= i64(n) || b >= i64(n) { return -1 }
            u := int(a); v := int(b)
            if adjacent[u][v] { return -1 }
            adjacent[u][v] = true; adjacent[v][u] = true
        }
        mut queue := [32]int{}
        mut parent := [32]int{}
        for root in 0 .. n {
            if visited[root] { continue }
            mut head := 0; mut tail := 1
            queue[0] = root; parent[root] = n; visited[root] = true
            for head < tail {
                u := queue[head]; head++
                for v in 0 .. n {
                    if !adjacent[u][v] { continue }
                    if !visited[v] { visited[v] = true; parent[v] = u; queue[tail] = v; tail++ } else if v != parent[u] { return 1 }
                }
            }
        }
        return 0
    }
}
