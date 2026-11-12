const MAX_N: usize = 8;
const MAX_M: usize = 20;
const MAX_INPUT_VALUES: usize = 2 + 3 * MAX_M + 1;
const INF: i64 = 1_000_000_000_000;

#[derive(Clone, Copy, Default)]
struct Edge {
    u: usize,
    v: usize,
    weight: i64,
}

fn shortest_tree(
    n: usize,
    m: usize,
    edges: &[Edge; MAX_M],
    center_kind: i32,
    center_root: usize,
    center_x2: i64,
    center_edge: usize,
    distance: &mut [i64; MAX_N],
    parent_edge: &mut [i64; MAX_N],
) {
    let mut settled = [false; MAX_N];
    distance.fill(INF);
    parent_edge.fill(-1);
    if center_kind == 0 {
        distance[center_root] = 0;
    } else {
        let mut u = edges[center_edge].u;
        let mut v = edges[center_edge].v;
        if u > v {
            std::mem::swap(&mut u, &mut v);
        }
        distance[u] = center_x2;
        distance[v] = 2 * edges[center_edge].weight - center_x2;
    }

    for _ in 0..n {
        let mut current = n;
        for vertex in 0..n {
            if !settled[vertex] &&
                (current == n || distance[vertex] < distance[current]) {
                current = vertex;
            }
        }
        if current == n || distance[current] == INF {
            return;
        }
        settled[current] = true;
        for edge_id in 0..m {
            let left = edges[edge_id].u;
            let right = edges[edge_id].v;
            if left == right {
                continue;
            }
            let neighbor = if current == left {
                right
            } else if current == right {
                left
            } else {
                continue;
            };
            let candidate = distance[current] + 2 * edges[edge_id].weight;
            if !settled[neighbor] && candidate < distance[neighbor] {
                distance[neighbor] = candidate;
                parent_edge[neighbor] = edge_id as i64;
            }
        }
    }
}

fn selected_tree_diameter(
    n: usize,
    edges: &[Edge; MAX_M],
    selected: &[usize; MAX_N],
) -> i64 {
    let mut adjacent = [[false; MAX_N]; MAX_N];
    let mut weight = [[0i64; MAX_N]; MAX_N];
    for index in 0..n.saturating_sub(1) {
        let edge = edges[selected[index]];
        adjacent[edge.u][edge.v] = true;
        adjacent[edge.v][edge.u] = true;
        weight[edge.u][edge.v] = edge.weight;
        weight[edge.v][edge.u] = edge.weight;
    }
    let mut diameter = 0;
    for source in 0..n {
        let mut distance = [-1i64; MAX_N];
        let mut parent = [n; MAX_N];
        let mut stack = [0usize; MAX_N];
        let mut top = 1;
        stack[0] = source;
        distance[source] = 0;
        while top > 0 {
            top -= 1;
            let current = stack[top];
            diameter = diameter.max(distance[current]);
            for neighbor in 0..n {
                if adjacent[current][neighbor]
                    && parent[current] != neighbor
                    && distance[neighbor] < 0
                {
                    parent[neighbor] = current;
                    distance[neighbor] = distance[current] + weight[current][neighbor];
                    stack[top] = neighbor;
                    top += 1;
                }
            }
        }
    }
    diameter
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn minimum_diameter_spanning_tree(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_VALUES {
        return -1;
    }
    let n_value = *input;
    let m_value = *input.add(1);
    if !(1..=MAX_N as i64).contains(&n_value) || !(0..=MAX_M as i64).contains(&m_value) {
        return -1;
    }
    let n = n_value as usize;
    let m = m_value as usize;
    if length != 2 + 3 * m {
        return -1;
    }

    let mut edges = [Edge::default(); MAX_M];
    let mut graph_distance = [[INF; MAX_N]; MAX_N];
    for vertex in 0..n {
        graph_distance[vertex][vertex] = 0;
    }
    for edge_id in 0..m {
        let offset = 2 + 3 * edge_id;
        let u_value = *input.add(offset);
        let v_value = *input.add(offset + 1);
        let edge_weight = *input.add(offset + 2);
        if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value
            || !(0..=9).contains(&edge_weight)
        {
            return -1;
        }
        let u = u_value as usize;
        let v = v_value as usize;
        edges[edge_id] = Edge { u, v, weight: edge_weight };
        if u != v && edge_weight < graph_distance[u][v] {
            graph_distance[u][v] = edge_weight;
            graph_distance[v][u] = edge_weight;
        }
    }
    for middle in 0..n {
        for left in 0..n {
            for right in 0..n {
                graph_distance[left][right] = graph_distance[left][right]
                    .min(graph_distance[left][middle] + graph_distance[middle][right]);
            }
        }
    }
    for vertex in 0..n {
        if graph_distance[0][vertex] == INF {
            return -1;
        }
    }

    let mut best_radius2 = INF;
    let mut best_kind = 0;
    let mut best_root = 0;
    let mut best_edge = 0;
    let mut best_x2 = 0;
    for root in 0..n {
        let eccentricity = graph_distance[root][..n].iter().copied().max().unwrap_or(0);
        let radius2 = 2 * eccentricity;
        if radius2 < best_radius2 {
            best_radius2 = radius2;
            best_kind = 0;
            best_root = root;
        }
    }
    for edge_id in 0..m {
        let mut u = edges[edge_id].u;
        let mut v = edges[edge_id].v;
        let edge_weight = edges[edge_id].weight;
        if u == v {
            continue;
        }
        if u > v {
            std::mem::swap(&mut u, &mut v);
        }
        for x2 in 0..=2 * edge_weight {
            let mut radius2 = 0;
            for vertex in 0..n {
                let from_u = 2 * graph_distance[u][vertex] + x2;
                let from_v = 2 * graph_distance[v][vertex] + 2 * edge_weight - x2;
                radius2 = radius2.max(from_u.min(from_v));
            }
            if radius2 < best_radius2 {
                best_radius2 = radius2;
                best_kind = 1;
                best_root = u;
                best_x2 = x2;
                best_edge = edge_id;
            }
        }
    }

    let mut center_distance = [0i64; MAX_N];
    let mut parent_edge = [0i64; MAX_N];
    shortest_tree(n, m, &edges, best_kind, best_root, best_x2, best_edge,
        &mut center_distance, &mut parent_edge);
    let mut selected = [0usize; MAX_N];
    let mut selected_count = 0;
    for vertex in 0..n {
        if parent_edge[vertex] >= 0 {
            selected[selected_count] = parent_edge[vertex] as usize;
            selected_count += 1;
        }
    }
    if selected_count + 2 == n && best_kind == 1 {
        let u = edges[best_edge].u;
        let v = edges[best_edge].v;
        if parent_edge[u] == -1 && parent_edge[v] == -1 {
            selected[selected_count] = best_edge;
            selected_count += 1;
        }
    }
    if selected_count != n - 1 {
        return -1;
    }
    selected[..selected_count].sort_unstable();

    let mut staged = [0i64; MAX_N];
    staged[0] = selected_tree_diameter(n, &edges, &selected);
    for index in 0..selected_count {
        staged[index + 1] = selected[index] as i64;
    }
    let required = 8 * n;
    if output.is_null() || capacity < required {
        return -2;
    }
    for index in 0..n {
        store_i64_le(output, 8 * index, staged[index]);
    }
    required as i64
}
