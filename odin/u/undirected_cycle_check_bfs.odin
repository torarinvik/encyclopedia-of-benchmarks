package undirected_cycle_check_bfs
import "core:c"

@(export)
undirected_cycle_check_bfs :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 514 do return -1
    if input[0] < 0 || input[0] > 32 || input[1] < 0 || input[1] > 256 do return -1
    n := int(input[0]); m := int(input[1])
    if length != c.size_t(2 + 2 * m) do return -1
    adjacent: [32][32]bool; visited: [32]bool
    for i := 0; i < m; i += 1 {
        a := input[2 + 2*i]; b := input[3 + 2*i]
        if a < 0 || b < 0 || a >= i64(n) || b >= i64(n) do return -1
        u := int(a); v := int(b)
        if adjacent[u][v] do return -1
        adjacent[u][v] = true; adjacent[v][u] = true
    }
    queue: [32]int; parent: [32]int
    for root := 0; root < n; root += 1 {
        if visited[root] do continue
        head := 0; tail := 1; queue[0] = root; parent[root] = n; visited[root] = true
        for head < tail {
            u := queue[head]; head += 1
            for v := 0; v < n; v += 1 {
                if !adjacent[u][v] do continue
                if !visited[v] { visited[v] = true; parent[v] = u; queue[tail] = v; tail += 1
                } else if v != parent[u] { return 1 }
            }
        }
    }
    return 0
}
