package bipartite_graph_dfs

import "core:c"

Max_Vertices :: 64
Max_Edges :: 256
Max_Input_Length :: 2 + 2 * Max_Edges
Max_Cells :: Max_Vertices * Max_Vertices

@(export)
bipartite_graph_dfs :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > Max_Input_Length do return -1
    n_value, m_value := input[0], input[1]
    if n_value < 1 || n_value > Max_Vertices || m_value < 0 || m_value > Max_Edges do return -1
    n, m := int(n_value), int(m_value)
    if length != 2 + 2 * m do return -1

    adjacency: [Max_Cells]bool
    for edge := 0; edge < m; edge += 1 {
        from_value, to_value := input[2 + 2 * edge], input[3 + 2 * edge]
        if from_value < 0 || from_value >= i64(n) || to_value < 0 || to_value >= i64(n) do return -1
        from, to := int(from_value), int(to_value)
        adjacency[from * n + to] = true
        adjacency[to * n + from] = true
    }
    color: [Max_Vertices]int
    stack: [Max_Vertices]int
    for i := 0; i < n; i += 1 { color[i] = -1 }
    for start := 0; start < n; start += 1 {
        if color[start] != -1 do continue
        top := 1
        stack[0] = start
        color[start] = 0
        for top > 0 {
            top -= 1
            node := stack[top]
            for neighbor := 0; neighbor < n; neighbor += 1 {
                if !adjacency[node * n + neighbor] do continue
                if color[neighbor] == -1 {
                    color[neighbor] = 1 - color[node]
                    stack[top] = neighbor
                    top += 1
                } else if color[neighbor] == color[node] do return 0
            }
        }
    }
    return 1
}
