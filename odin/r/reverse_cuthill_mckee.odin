package reverse_cuthill_mckee
import "core:c"

Max_N :: 8
Max_Input_Length :: 59

@(export)
reverse_cuthill_mckee :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > Max_Input_Length do return -1
    n64 := input[0]
    m64 := input[1]
    if n64 < 1 || n64 > Max_N do return -1
    n := int(n64)
    if m64 < 0 || m64 > i64(n*(n-1)/2) do return -1
    m := int(m64)
    if length != c.size_t(2+2*m) do return -1

    adjacency: [Max_N][Max_N]bool
    for edge in 0..<m {
        u64 := input[2+2*edge]
        v64 := input[3+2*edge]
        if u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64 || u64 == v64 do return -1
        u := int(u64)
        v := int(v64)
        if adjacency[u][v] do return -1
        adjacency[u][v] = true
        adjacency[v][u] = true
    }

    degree: [Max_N]int
    for u in 0..<n {
        for v in 0..<n {
            if adjacency[u][v] do degree[u] += 1
        }
    }

    visited: [Max_N]bool
    queue: [Max_N]int
    cm_order: [Max_N]int
    order_count := 0
    for order_count < n {
        root := -1
        for v in 0..<n {
            if !visited[v] {
                if root < 0 {
                    root = v
                } else if degree[v] < degree[root] ||
                    degree[v] == degree[root] && v < root {
                    root = v
                }
            }
        }
        if root < 0 do return -1
        head := 0
        tail := 1
        queue[0] = root
        visited[root] = true
        for head < tail {
            current := queue[head]
            head += 1
            cm_order[order_count] = current
            order_count += 1

            neighbors: [Max_N]int
            neighbor_count := 0
            for v in 0..<n {
                if adjacency[current][v] && !visited[v] {
                    neighbors[neighbor_count] = v
                    neighbor_count += 1
                }
            }
            for i in 1..<neighbor_count {
                key := neighbors[i]
                j := i
                for j > 0 && (degree[neighbors[j-1]] > degree[key] ||
                    degree[neighbors[j-1]] == degree[key] && neighbors[j-1] > key) {
                    neighbors[j] = neighbors[j-1]
                    j -= 1
                }
                neighbors[j] = key
            }
            for i in 0..<neighbor_count {
                next := neighbors[i]
                if !visited[next] {
                    visited[next] = true
                    queue[tail] = next
                    tail += 1
                }
            }
        }
    }

    rank: [Max_N]int
    for i in 0..<n { rank[cm_order[n-1-i]] = i }
    bandwidth := 0
    for u in 0..<n {
        for v in u+1..<n {
            if adjacency[u][v] {
                distance := rank[u]-rank[v]
                if distance < 0 do distance = -distance
                if distance > bandwidth do bandwidth = distance
            }
        }
    }
    rank_word: i64 = 0
    for i in 0..<n { rank_word |= i64(cm_order[n-1-i]) << (3*i) }
    return (i64(bandwidth) << 24) | rank_word
}
