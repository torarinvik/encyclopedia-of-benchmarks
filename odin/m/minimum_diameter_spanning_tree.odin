package minimum_diameter_spanning_tree

import "core:c"

MAX_N :: 8
MAX_M :: 20
MAX_INPUT_VALUES :: 2 + 3 * MAX_M + 1
INF :: i64(1_000_000_000_000)

shortest_tree :: proc "contextless" (n, m: int, edge_u, edge_v: [^]int,
    edge_weight: [^]i64, center_kind, center_root: int, center_x2: i64,
    center_edge: int, distance, parent_edge: [^]i64) {
    settled: [MAX_N]bool
    for vertex := 0; vertex < n; vertex += 1 {
        distance[vertex] = INF
        parent_edge[vertex] = -1
    }
    if center_kind == 0 {
        distance[center_root] = 0
    } else {
        u := edge_u[center_edge]
        v := edge_v[center_edge]
        if u > v { u, v = v, u }
        distance[u] = center_x2
        distance[v] = 2 * edge_weight[center_edge] - center_x2
    }
    for step := 0; step < n; step += 1 {
        current := n
        for vertex := 0; vertex < n; vertex += 1 {
            if !settled[vertex] && (current == n || distance[vertex] < distance[current]) {
                current = vertex
            }
        }
        if current == n || distance[current] == INF do return
        settled[current] = true
        for edge_id := 0; edge_id < m; edge_id += 1 {
            left := edge_u[edge_id]
            right := edge_v[edge_id]
            if left == right do continue
            neighbor := n
            if current == left do neighbor = right
            else if current == right do neighbor = left
            else do continue
            candidate := distance[current] + 2 * edge_weight[edge_id]
            if !settled[neighbor] && candidate < distance[neighbor] {
                distance[neighbor] = candidate
                parent_edge[neighbor] = i64(edge_id)
            }
        }
    }
}

selected_tree_diameter :: proc "contextless" (n: int, selected: [^]int,
    edge_u, edge_v: [^]int, edge_weight: [^]i64) -> i64 {
    adjacent: [MAX_N][MAX_N]bool
    weight: [MAX_N][MAX_N]i64
    for u := 0; u < n; u += 1 {
        for v := 0; v < n; v += 1 {
            adjacent[u][v] = false
            weight[u][v] = 0
        }
    }
    for index := 0; index + 1 < n; index += 1 {
        edge_id := selected[index]
        u := edge_u[edge_id]
        v := edge_v[edge_id]
        adjacent[u][v] = true
        adjacent[v][u] = true
        weight[u][v] = edge_weight[edge_id]
        weight[v][u] = edge_weight[edge_id]
    }
    diameter: i64 = 0
    for source := 0; source < n; source += 1 {
        distance: [MAX_N]i64
        parent: [MAX_N]int
        stack: [MAX_N]int
        for vertex := 0; vertex < n; vertex += 1 {
            distance[vertex] = -1
            parent[vertex] = n
        }
        top := 1
        stack[0] = source
        distance[source] = 0
        for top > 0 {
            top -= 1
            current := stack[top]
            if distance[current] > diameter do diameter = distance[current]
            for neighbor := 0; neighbor < n; neighbor += 1 {
                if adjacent[current][neighbor] && parent[current] != neighbor && distance[neighbor] < 0 {
                    parent[neighbor] = current
                    distance[neighbor] = distance[current] + weight[current][neighbor]
                    stack[top] = neighbor
                    top += 1
                }
            }
        }
    }
    return diameter
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8((bits >> (8 * byte)) & 255)
    }
}

@(export)
minimum_diameter_spanning_tree :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT_VALUES do return -1
    n_value := input[0]
    m_value := input[1]
    if n_value < 1 || n_value > MAX_N || m_value < 0 || m_value > MAX_M do return -1
    n := int(n_value)
    m := int(m_value)
    if length != c.size_t(2 + 3 * m) do return -1

    edge_u: [MAX_M]int
    edge_v: [MAX_M]int
    edge_weight: [MAX_M]i64
    graph_distance: [MAX_N][MAX_N]i64
    for u := 0; u < n; u += 1 {
        for v := 0; v < n; v += 1 {
            graph_distance[u][v] = INF
            if u == v do graph_distance[u][v] = 0
        }
    }
    for edge_id := 0; edge_id < m; edge_id += 1 {
        offset := 2 + 3 * edge_id
        u_value := input[offset]
        v_value := input[offset + 1]
        edge_w := input[offset + 2]
        if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value ||
            edge_w < 0 || edge_w > 9 do return -1
        u := int(u_value)
        v := int(v_value)
        edge_u[edge_id] = u
        edge_v[edge_id] = v
        edge_weight[edge_id] = edge_w
        if u != v && edge_w < graph_distance[u][v] {
            graph_distance[u][v] = edge_w
            graph_distance[v][u] = edge_w
        }
    }
    for middle := 0; middle < n; middle += 1 {
        for left := 0; left < n; left += 1 {
            for right := 0; right < n; right += 1 {
                candidate := graph_distance[left][middle] + graph_distance[middle][right]
                if candidate < graph_distance[left][right] do graph_distance[left][right] = candidate
            }
        }
    }
    for vertex := 0; vertex < n; vertex += 1 {
        if graph_distance[0][vertex] == INF do return -1
    }

    best_radius2 := INF
    best_kind := 0
    best_root := 0
    best_edge := 0
    best_x2: i64 = 0
    for root := 0; root < n; root += 1 {
        eccentricity: i64 = 0
        for vertex := 0; vertex < n; vertex += 1 {
            if graph_distance[root][vertex] > eccentricity do eccentricity = graph_distance[root][vertex]
        }
        radius2 := 2 * eccentricity
        if radius2 < best_radius2 {
            best_radius2 = radius2
            best_kind = 0
            best_root = root
        }
    }
    for edge_id := 0; edge_id < m; edge_id += 1 {
        u := edge_u[edge_id]
        v := edge_v[edge_id]
        edge_w := edge_weight[edge_id]
        if u == v do continue
        if u > v do u, v = v, u
        for x2: i64 = 0; x2 <= 2 * edge_w; x2 += 1 {
            radius2: i64 = 0
            for vertex := 0; vertex < n; vertex += 1 {
                from_u := 2 * graph_distance[u][vertex] + x2
                from_v := 2 * graph_distance[v][vertex] + 2 * edge_w - x2
                value := from_u
                if from_v < value do value = from_v
                if value > radius2 do radius2 = value
            }
            if radius2 < best_radius2 {
                best_radius2 = radius2
                best_kind = 1
                best_root = u
                best_x2 = x2
                best_edge = edge_id
            }
        }
    }

    center_distance: [MAX_N]i64
    parent_edge: [MAX_N]i64
    shortest_tree(n, m, &edge_u[0], &edge_v[0], &edge_weight[0], best_kind,
        best_root, best_x2, best_edge, &center_distance[0], &parent_edge[0])
    selected: [MAX_N]int
    selected_count := 0
    for vertex := 0; vertex < n; vertex += 1 {
        if parent_edge[vertex] >= 0 {
            selected[selected_count] = int(parent_edge[vertex])
            selected_count += 1
        }
    }
    if selected_count + 2 == n && best_kind == 1 {
        u := edge_u[best_edge]
        v := edge_v[best_edge]
        if parent_edge[u] == -1 && parent_edge[v] == -1 {
            selected[selected_count] = best_edge
            selected_count += 1
        }
    }
    if selected_count != n - 1 do return -1
    for left := 0; left < selected_count; left += 1 {
        for right := left + 1; right < selected_count; right += 1 {
            if selected[right] < selected[left] do selected[left], selected[right] = selected[right], selected[left]
        }
    }

    staged: [MAX_N]i64
    staged[0] = selected_tree_diameter(n, &selected[0], &edge_u[0], &edge_v[0], &edge_weight[0])
    for index := 0; index < selected_count; index += 1 do staged[index + 1] = i64(selected[index])
    required := 8 * n
    if output == nil || capacity < c.size_t(required) do return -2
    for index := 0; index < n; index += 1 do store_i64_le(output, 8 * index, staged[index])
    return i64(required)
}
