const MAX_VERTICES: usize = 12;
const MAX_EDGES: usize = 24;
const MAX_INPUT_LENGTH: usize = 2 + 3 * MAX_EDGES + 1;

fn find_root(parent: &mut [usize; MAX_VERTICES], vertex: usize) -> usize {
    let mut root = vertex;
    while parent[root] != root { root = parent[root]; }
    let mut current = vertex;
    while parent[current] != current {
        let next = parent[current];
        parent[current] = root;
        current = next;
    }
    root
}

fn join_roots(parent: &mut [usize; MAX_VERTICES], left: usize, right: usize) {
    let a = find_root(parent, left);
    let b = find_root(parent, right);
    if a != b { parent[b] = a; }
}

fn alternative_path_exists(left: &[usize; MAX_EDGES], right: &[usize; MAX_EDGES],
    edge_id: &[usize; MAX_EDGES], edge_count: usize, omitted: usize,
    source: usize, target: usize) -> bool {
    let mut seen = [false; MAX_VERTICES];
    let mut queue = [0usize; MAX_VERTICES];
    let (mut head, mut tail) = (0usize, 0usize);
    seen[source] = true;
    queue[tail] = source;
    tail += 1;
    while head < tail {
        let vertex = queue[head];
        head += 1;
        if vertex == target { return true; }
        for edge in 0..edge_count {
            if edge_id[edge] == omitted { continue; }
            let neighbor = if left[edge] == vertex { right[edge] }
                else if right[edge] == vertex { left[edge] }
                else { MAX_VERTICES };
            if neighbor < MAX_VERTICES && !seen[neighbor] {
                seen[neighbor] = true;
                queue[tail] = neighbor;
                tail += 1;
            }
        }
    }
    false
}

#[no_mangle]
pub unsafe extern "C" fn mst_edge_classification(
    input_ptr: *const i64, length: usize, output_ptr: *mut u8, output_capacity: usize,
) -> i64 {
    if input_ptr.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(input_ptr, length);
    if input[0] < 1 || input[0] > MAX_VERTICES as i64 || input[1] < 0 || input[1] > MAX_EDGES as i64 { return -1; }
    let vertex_count = input[0] as usize;
    let edge_count = input[1] as usize;
    if length != 2 + 3 * edge_count { return -1; }

    let mut left = [0usize; MAX_EDGES];
    let mut right = [0usize; MAX_EDGES];
    let mut weight = [0usize; MAX_EDGES];
    let mut order = [0usize; MAX_EDGES];
    let mut classes = [0u8; MAX_EDGES];
    for edge in 0..edge_count {
        let u = input[2 + 3 * edge];
        let v = input[3 + 3 * edge];
        let w = input[4 + 3 * edge];
        if u < 0 || u >= v || v >= vertex_count as i64 || w < 0 || w > 20 { return -1; }
        left[edge] = u as usize;
        right[edge] = v as usize;
        weight[edge] = w as usize;
        order[edge] = edge;
        for prior in 0..edge {
            if left[prior] == left[edge] && right[prior] == right[edge] { return -1; }
        }
    }
    for i in 1..edge_count {
        let item = order[i];
        let mut j = i;
        while j > 0 && (weight[order[j - 1]] > weight[item] ||
            (weight[order[j - 1]] == weight[item] && order[j - 1] > item)) {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = item;
    }

    let mut parent = [0usize; MAX_VERTICES];
    for vertex in 0..vertex_count { parent[vertex] = vertex; }
    let mut start = 0;
    while start < edge_count {
        let mut stop = start + 1;
        let group_weight = weight[order[start]];
        while stop < edge_count && weight[order[stop]] == group_weight { stop += 1; }
        let mut q_left = [0usize; MAX_EDGES];
        let mut q_right = [0usize; MAX_EDGES];
        let mut q_id = [0usize; MAX_EDGES];
        let mut q_count = 0;
        for pos in start..stop {
            let id = order[pos];
            let a = find_root(&mut parent, left[id]);
            let b = find_root(&mut parent, right[id]);
            if a != b {
                q_left[q_count] = a;
                q_right[q_count] = b;
                q_id[q_count] = id;
                q_count += 1;
            }
        }
        for edge in 0..q_count {
            classes[q_id[edge]] = if alternative_path_exists(&q_left, &q_right, &q_id,
                q_count, q_id[edge], q_left[edge], q_right[edge]) { 1 } else { 2 };
        }
        for pos in start..stop {
            let id = order[pos];
            join_roots(&mut parent, left[id], right[id]);
        }
        start = stop;
    }
    let representative = find_root(&mut parent, 0);
    for vertex in 1..vertex_count {
        if find_root(&mut parent, vertex) != representative { return -1; }
    }
    if output_capacity < edge_count || (edge_count > 0 && output_ptr.is_null()) { return -2; }
    if edge_count > 0 {
        let output = std::slice::from_raw_parts_mut(output_ptr, edge_count);
        output.copy_from_slice(&classes[..edge_count]);
    }
    edge_count as i64
}
