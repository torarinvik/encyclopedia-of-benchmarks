const MAX_N: usize = 16;
const MAX_EDGES: usize = MAX_N - 1;
const MAX_ARCS: usize = 2 * MAX_EDGES;
const MAX_INPUT_LENGTH: usize = 48;

fn find_root(sets: &mut [i32; MAX_N], mut vertex: usize) -> usize {
    while sets[vertex] != vertex as i32 {
        sets[vertex] = sets[sets[vertex] as usize];
        vertex = sets[vertex] as usize;
    }
    vertex
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for (byte, part) in bytes.iter().enumerate() {
        *output.add(offset + byte) = *part;
    }
}

#[no_mangle]
pub unsafe extern "C" fn tree_random_walk_edge_hitting_cost(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    let root_value = values[1];
    if !(1..=MAX_N as i64).contains(&n_value) || root_value < 0 || root_value >= n_value {
        return -1;
    }
    let n = n_value as usize;
    let root = root_value as usize;
    let edge_count = n - 1;
    if length != 2 + 3 * edge_count {
        return -1;
    }

    let mut head = [-1i32; MAX_N];
    let mut to = [0i32; MAX_ARCS];
    let mut next = [0i32; MAX_ARCS];
    let mut sets = [0i32; MAX_N];
    let mut input_u = [0usize; MAX_EDGES];
    let mut input_v = [0usize; MAX_EDGES];
    let mut incident_sum = [0i64; MAX_N];
    let mut down = [0i64; MAX_N];
    let mut up = [0i64; MAX_N];
    for vertex in 0..n {
        sets[vertex] = vertex as i32;
    }

    let mut arc_count = 0usize;
    for edge in 0..edge_count {
        let offset = 2 + 3 * edge;
        let u_value = values[offset];
        let v_value = values[offset + 1];
        let weight = values[offset + 2];
        if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value
            || u_value == v_value || !(1..=9).contains(&weight)
        {
            return -1;
        }
        let u = u_value as usize;
        let v = v_value as usize;
        let set_u = find_root(&mut sets, u);
        let set_v = find_root(&mut sets, v);
        if set_u == set_v {
            return -1;
        }
        sets[set_v] = set_u as i32;
        input_u[edge] = u;
        input_v[edge] = v;
        to[arc_count] = v as i32;
        next[arc_count] = head[u];
        head[u] = arc_count as i32;
        arc_count += 1;
        to[arc_count] = u as i32;
        next[arc_count] = head[v];
        head[v] = arc_count as i32;
        arc_count += 1;
        incident_sum[u] += weight;
        incident_sum[v] += weight;
    }

    let output_bytes = 16 * edge_count;
    if output.is_null() || capacity < output_bytes {
        return -2;
    }

    let mut parent = [-1i32; MAX_N];
    let mut order = [0usize; MAX_N];
    parent[root] = root as i32;
    order[0] = root;
    let mut order_size = 1usize;
    let mut cursor = 0usize;
    while cursor < order_size {
        let vertex = order[cursor];
        let mut arc = head[vertex];
        while arc >= 0 {
            let index = arc as usize;
            let neighbor = to[index] as usize;
            if parent[neighbor] == -1 {
                parent[neighbor] = vertex as i32;
                order[order_size] = neighbor;
                order_size += 1;
            }
            arc = next[index];
        }
        cursor += 1;
    }

    for position in (0..n).rev() {
        let vertex = order[position];
        down[vertex] = incident_sum[vertex];
        let mut arc = head[vertex];
        while arc >= 0 {
            let index = arc as usize;
            let child = to[index] as usize;
            if parent[child] == vertex as i32 {
                down[vertex] += down[child];
            }
            arc = next[index];
        }
    }
    for position in 0..n {
        let vertex = order[position];
        let mut arc = head[vertex];
        while arc >= 0 {
            let index = arc as usize;
            let child = to[index] as usize;
            if parent[child] == vertex as i32 {
                up[child] = up[vertex] + down[vertex] - down[child];
            }
            arc = next[index];
        }
    }
    for edge in 0..edge_count {
        let u = input_u[edge];
        let v = input_v[edge];
        let (toward_v, toward_u) = if parent[u] == v as i32 {
            (down[u], up[u])
        } else {
            (up[v], down[v])
        };
        store_i64_le(output, 16 * edge, toward_v);
        store_i64_le(output, 16 * edge + 8, toward_u);
    }
    output_bytes as i64
}
