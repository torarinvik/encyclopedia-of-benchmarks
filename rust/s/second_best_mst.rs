const MAX_N: usize = 8;
const MAX_M: usize = 20;

fn find_root(parent: &mut [usize; MAX_N], mut vertex: usize) -> usize {
    while parent[vertex] != vertex {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    vertex
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn second_best_mst(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 2 + 3 * MAX_M {
        return -1;
    }
    let n_value = *input;
    let m_value = *input.add(1);
    if !(1..=MAX_N as i64).contains(&n_value)
        || m_value < n_value - 1
        || m_value > MAX_M as i64
    {
        return -1;
    }
    let n = n_value as usize;
    let m = m_value as usize;
    if length != 2 + 3 * m {
        return -1;
    }

    let mut edge_u = [0usize; MAX_M];
    let mut edge_v = [0usize; MAX_M];
    let mut edge_weight = [0i64; MAX_M];
    let mut order = [0usize; MAX_M];
    let mut seen = [[false; MAX_N]; MAX_N];
    for edge in 0..m {
        let u_value = *input.add(2 + 3 * edge);
        let v_value = *input.add(3 + 3 * edge);
        let weight = *input.add(4 + 3 * edge);
        if u_value < 0 || u_value >= v_value || v_value >= n_value || !(0..=1_000_000).contains(&weight) {
            return -1;
        }
        let u = u_value as usize;
        let v = v_value as usize;
        if seen[u][v] {
            return -1;
        }
        seen[u][v] = true;
        edge_u[edge] = u;
        edge_v[edge] = v;
        edge_weight[edge] = weight;
        order[edge] = edge;
    }

    for i in 1..m {
        let edge = order[i];
        let mut j = i;
        while j > 0 && (edge_weight[order[j - 1]] > edge_weight[edge]
            || (edge_weight[order[j - 1]] == edge_weight[edge] && order[j - 1] > edge))
        {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = edge;
    }

    let mut dsu = [0usize; MAX_N];
    let mut component_size = [0usize; MAX_N];
    for vertex in 0..n {
        dsu[vertex] = vertex;
        component_size[vertex] = 1;
    }
    let mut in_mst = [false; MAX_M];
    let mut tree_to = [[0usize; MAX_N]; MAX_N];
    let mut tree_edge = [[0usize; MAX_N]; MAX_N];
    let mut degree = [0usize; MAX_N];
    let mut selected = 0;
    let mut mst_weight = 0i64;
    for &edge in order[..m].iter() {
        let mut root_u = find_root(&mut dsu, edge_u[edge]);
        let mut root_v = find_root(&mut dsu, edge_v[edge]);
        if root_u == root_v {
            continue;
        }
        if component_size[root_u] < component_size[root_v] {
            std::mem::swap(&mut root_u, &mut root_v);
        }
        dsu[root_v] = root_u;
        component_size[root_u] += component_size[root_v];
        in_mst[edge] = true;
        selected += 1;
        mst_weight += edge_weight[edge];
        tree_to[edge_u[edge]][degree[edge_u[edge]]] = edge_v[edge];
        tree_edge[edge_u[edge]][degree[edge_u[edge]]] = edge;
        degree[edge_u[edge]] += 1;
        tree_to[edge_v[edge]][degree[edge_v[edge]]] = edge_u[edge];
        tree_edge[edge_v[edge]][degree[edge_v[edge]]] = edge;
        degree[edge_v[edge]] += 1;
    }
    if selected != n - 1 {
        return -1;
    }

    let mut second_weight = -1i64;
    let mut entering_edge = -1i64;
    let mut leaving_edge = -1i64;
    for added in 0..m {
        if in_mst[added] {
            continue;
        }
        let mut parent = [-1i64; MAX_N];
        let mut parent_edge = [-1i64; MAX_N];
        let mut queue = [0usize; MAX_N];
        let mut head = 0;
        let mut tail = 0;
        let start = edge_u[added];
        let target = edge_v[added];
        parent[start] = start as i64;
        queue[tail] = start;
        tail += 1;
        while head < tail && parent[target] < 0 {
            let vertex = queue[head];
            head += 1;
            for i in 0..degree[vertex] {
                let next = tree_to[vertex][i];
                if parent[next] >= 0 {
                    continue;
                }
                parent[next] = vertex as i64;
                parent_edge[next] = tree_edge[vertex][i] as i64;
                queue[tail] = next;
                tail += 1;
            }
        }
        let mut first_weight = -1i64;
        let mut second_path_weight = -1i64;
        let mut first_edge = -1i64;
        let mut second_path_edge = -1i64;
        let mut vertex = target;
        while vertex != start {
            let path_edge = parent_edge[vertex];
            let weight = edge_weight[path_edge as usize];
            if weight > first_weight {
                second_path_weight = first_weight;
                second_path_edge = first_edge;
                first_weight = weight;
                first_edge = path_edge;
            } else if weight == first_weight {
                if first_edge < 0 || path_edge < first_edge {
                    first_edge = path_edge;
                }
            } else if weight > second_path_weight {
                second_path_weight = weight;
                second_path_edge = path_edge;
            } else if weight == second_path_weight
                && (second_path_edge < 0 || path_edge < second_path_edge)
            {
                second_path_edge = path_edge;
            }
            vertex = parent[vertex] as usize;
        }
        let mut removed_weight = -1i64;
        let mut removed_edge = -1i64;
        if edge_weight[added] > first_weight {
            removed_weight = first_weight;
            removed_edge = first_edge;
        } else if edge_weight[added] == first_weight && second_path_weight >= 0 {
            removed_weight = second_path_weight;
            removed_edge = second_path_edge;
        }
        if removed_edge < 0 {
            continue;
        }
        let candidate = mst_weight + edge_weight[added] - removed_weight;
        if second_weight < 0
            || candidate < second_weight
            || (candidate == second_weight
                && ((added as i64) < entering_edge
                    || ((added as i64) == entering_edge && removed_edge < leaving_edge)))
        {
            second_weight = candidate;
            entering_edge = added as i64;
            leaving_edge = removed_edge;
        }
    }

    if output.is_null() || capacity < 32 {
        return -2;
    }
    store_i64_le(output, 0, mst_weight);
    store_i64_le(output, 8, second_weight);
    store_i64_le(output, 16, entering_edge);
    store_i64_le(output, 24, leaving_edge);
    32
}
