const MAX_N: usize = 6;
const MAX_NODES: usize = 10;
const MAX_EDGES: usize = 9;
const MAX_OUTPUT_BYTES: usize = 152;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

fn tree_distance(node_count: usize, edge_count: usize, edge_u: &[i32; MAX_EDGES],
                 edge_v: &[i32; MAX_EDGES], edge_w: &[i64; MAX_EDGES],
                 start: usize, target: usize, distance: &mut [i64; MAX_NODES]) -> bool {
    let mut parent = [-1i32; MAX_NODES];
    let mut queue = [0usize; MAX_NODES];
    let mut head = 0usize;
    let mut tail = 0usize;
    parent[start] = start as i32;
    distance[start] = 0;
    queue[tail] = start;
    tail += 1;
    while head < tail {
        let node = queue[head]; head += 1;
        if node == target { return true; }
        for e in 0..edge_count {
            let u = edge_u[e] as usize;
            let v = edge_v[e] as usize;
            let neighbor = if u == node { v } else if v == node { u } else { continue };
            if parent[neighbor] >= 0 { continue; }
            parent[neighbor] = node as i32;
            distance[neighbor] = distance[node] + edge_w[e];
            queue[tail] = neighbor; tail += 1;
        }
    }
    false
}

#[no_mangle]
pub unsafe extern "C" fn phylogenetic_tree_from_distance_matrix(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_N * MAX_N + 2 { return -1; }
    let raw_n = *input;
    if raw_n < 2 || raw_n > MAX_N as i64 || length != 1 + raw_n as usize * raw_n as usize { return -1; }
    let n = raw_n as usize;
    let mut d = [0i64; MAX_N * MAX_N];
    for i in 0..n { for j in 0..n {
        let value = *input.add(1 + i * n + j);
        if (i == j && value != 0) || (i != j && !(1..=32).contains(&value)) { return -1; }
        d[i * MAX_N + j] = value;
    }}
    for i in 0..n { for j in i + 1..n { if d[i * MAX_N + j] != d[j * MAX_N + i] { return -1; } }}

    let mut edge_u = [0i32; MAX_EDGES];
    let mut edge_v = [0i32; MAX_EDGES];
    let mut edge_w = [0i64; MAX_EDGES];
    let mut edge_count = 1usize;
    edge_u[0] = 0; edge_v[0] = 1; edge_w[0] = 2 * d[1];
    let mut label_node = [0usize; MAX_N];
    label_node[1] = 1;
    let mut label_mask = [0u32; MAX_NODES];
    label_mask[0] = 1; label_mask[1] = 2;
    let mut node_count = 2usize;
    let mut additive = true;

    for leaf in 2..n {
        if !additive { break; }
        let mut limb2 = i64::MAX;
        for i in 0..leaf { for j in i + 1..leaf {
            limb2 = limb2.min(d[i * MAX_N + leaf] + d[j * MAX_N + leaf] - d[i * MAX_N + j]);
        }}
        if limb2 < 0 { additive = false; break; }
        let mut witness: Option<(usize, usize, i64)> = None;
        'pair: for i in 0..leaf { for j in i + 1..leaf {
            let from_i = 2 * d[i * MAX_N + leaf] - limb2;
            let from_j = 2 * d[j * MAX_N + leaf] - limb2;
            if from_i >= 0 && from_j >= 0 && 2 * d[i * MAX_N + j] == from_i + from_j {
                witness = Some((i, j, from_i)); break 'pair;
            }
        }}
        let (wi, wj, attach_distance) = match witness { Some(value) => value, None => { additive = false; break; } };
        let start = label_node[wi]; let target = label_node[wj];
        let mut parent_node = [-1i32; MAX_NODES];
        let mut parent_edge = [-1i32; MAX_NODES];
        let mut queue = [0usize; MAX_NODES];
        let mut head = 0usize; let mut tail = 0usize;
        parent_node[start] = start as i32; queue[tail] = start; tail += 1;
        while head < tail && parent_node[target] < 0 {
            let node = queue[head]; head += 1;
            for e in 0..edge_count {
                let u = edge_u[e] as usize; let v = edge_v[e] as usize;
                let neighbor = if u == node { v } else if v == node { u } else { continue };
                if parent_node[neighbor] >= 0 { continue; }
                parent_node[neighbor] = node as i32; parent_edge[neighbor] = e as i32;
                queue[tail] = neighbor; tail += 1;
            }
        }
        if parent_node[target] < 0 { additive = false; break; }
        let mut reverse_nodes = [0usize; MAX_NODES];
        let mut reverse_edges = [0usize; MAX_NODES];
        let mut path_node_count = 1usize; let mut path_edge_count = 0usize;
        reverse_nodes[0] = target;
        let mut current = target;
        while current != start {
            reverse_edges[path_edge_count] = parent_edge[current] as usize; path_edge_count += 1;
            current = parent_node[current] as usize;
            reverse_nodes[path_node_count] = current; path_node_count += 1;
        }
        let mut path_nodes = [0usize; MAX_NODES];
        let mut path_edges = [0usize; MAX_NODES];
        for i in 0..path_node_count { path_nodes[i] = reverse_nodes[path_node_count - 1 - i]; }
        for i in 0..path_edge_count { path_edges[i] = reverse_edges[path_edge_count - 1 - i]; }
        let mut elapsed = 0i64;
        let mut attach_node: Option<usize> = None;
        let mut split: Option<(usize, usize, usize, i64)> = None;
        for step in 0..path_node_count {
            if attach_distance == elapsed { attach_node = Some(path_nodes[step]); break; }
            if step == path_edge_count { break; }
            let e = path_edges[step]; let weight = edge_w[e];
            if elapsed < attach_distance && attach_distance < elapsed + weight {
                split = Some((e, path_nodes[step], path_nodes[step + 1], attach_distance - elapsed)); break;
            }
            elapsed += weight;
        }
        if attach_node.is_none() && split.is_none() { additive = false; break; }
        if let Some((e, left, right, first)) = split {
            if node_count >= MAX_NODES || edge_count >= MAX_EDGES { additive = false; break; }
            let internal = node_count; node_count += 1;
            let whole = edge_w[e];
            edge_u[e] = left as i32; edge_v[e] = internal as i32; edge_w[e] = first;
            edge_u[edge_count] = internal as i32; edge_v[edge_count] = right as i32;
            edge_w[edge_count] = whole - first; edge_count += 1;
            attach_node = Some(internal);
        }
        let attach = attach_node.unwrap();
        if limb2 == 0 {
            if label_mask[attach] != 0 { additive = false; break; }
            label_node[leaf] = attach; label_mask[attach] |= 1 << leaf;
        } else {
            if node_count >= MAX_NODES || edge_count >= MAX_EDGES { additive = false; break; }
            let new_leaf = node_count; node_count += 1;
            label_node[leaf] = new_leaf; label_mask[new_leaf] = 1 << leaf;
            edge_u[edge_count] = attach as i32; edge_v[edge_count] = new_leaf as i32;
            edge_w[edge_count] = limb2; edge_count += 1;
        }
    }
    if !additive { return 0; }

    let mut distances = [0i64; MAX_NODES];
    for i in 0..n { for j in i + 1..n {
        if !tree_distance(node_count, edge_count, &edge_u, &edge_v, &edge_w,
                label_node[i], label_node[j], &mut distances) ||
                distances[label_node[j]] != 2 * d[i * MAX_N + j] { return 0; }
    }}

    let full_mask = (1u32 << n) - 1;
    let mut masks = [0i64; MAX_EDGES];
    let mut weights = [0i64; MAX_EDGES];
    for e in 0..edge_count {
        let mut seen = 1u32 << edge_u[e];
        let mut queue = [0usize; MAX_NODES];
        let mut head = 0usize; let mut tail = 0usize;
        queue[tail] = edge_u[e] as usize; tail += 1;
        let mut mask = 0u32;
        while head < tail {
            let node = queue[head]; head += 1; mask |= label_mask[node];
            for other in 0..edge_count {
                if other == e { continue; }
                let u = edge_u[other] as usize; let v = edge_v[other] as usize;
                let neighbor = if u == node { v } else if v == node { u } else { continue };
                if seen & (1u32 << neighbor) != 0 { continue; }
                seen |= 1u32 << neighbor; queue[tail] = neighbor; tail += 1;
            }
        }
        if mask & 1 == 0 { mask = full_mask ^ mask; }
        masks[e] = mask as i64; weights[e] = edge_w[e];
    }
    for i in 1..edge_count {
        let mask = masks[i]; let weight = weights[i]; let mut j = i;
        while j > 0 && (masks[j - 1] > mask || masks[j - 1] == mask && weights[j - 1] > weight) {
            masks[j] = masks[j - 1]; weights[j] = weights[j - 1]; j -= 1;
        }
        masks[j] = mask; weights[j] = weight;
    }
    let output_bytes = 8 * (1 + 2 * edge_count);
    if output.is_null() { return -2; }
    if capacity < output_bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    store_i64_le(staged.as_mut_ptr(), 0, edge_count as i64);
    for i in 0..edge_count {
        store_i64_le(staged.as_mut_ptr(), 8 * (1 + 2 * i), masks[i]);
        store_i64_le(staged.as_mut_ptr(), 8 * (2 + 2 * i), weights[i]);
    }
    for byte in 0..output_bytes { *output.add(byte) = staged[byte]; }
    output_bytes as i64
}
