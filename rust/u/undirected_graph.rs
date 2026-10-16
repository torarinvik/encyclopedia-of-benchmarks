const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 28;
const MAX_OPERATIONS: usize = 128;
const MAX_INPUT_LENGTH: usize = 599;
const MIN_WEIGHT: i64 = -1_000_000;
const MAX_WEIGHT: i64 = 1_000_000;
const FNV_OFFSET: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;
const RESULT_MASK: u64 = 0x7fffffffffffffff;

fn hash_byte(hash: u64, value: u8) -> u64 {
    (hash ^ value as u64).wrapping_mul(FNV_PRIME)
}

fn hash_i32(mut hash: u64, value: i64) -> u64 {
    let bits = value as u32;
    for shift in [0, 8, 16, 24] { hash = hash_byte(hash, (bits >> shift) as u8); }
    hash
}

fn hash_u32(mut hash: u64, value: u32) -> u64 {
    for shift in [0, 8, 16, 24] { hash = hash_byte(hash, (value >> shift) as u8); }
    hash
}

fn edge_bit_index(n: usize, mut u: usize, mut v: usize) -> usize {
    if u > v { std::mem::swap(&mut u, &mut v); }
    (0..u).map(|first| n - first - 1).sum::<usize>() + v - u - 1
}

fn component_count(n: usize, present: &[u8; 64]) -> usize {
    let mut seen = [false; MAX_VERTICES];
    let mut count = 0;
    for root in 0..n {
        if seen[root] { continue; }
        count += 1;
        seen[root] = true;
        let mut stack = [0_usize; MAX_VERTICES];
        let mut size = 1;
        stack[0] = root;
        while size > 0 {
            size -= 1;
            let node = stack[size];
            for neighbor in 0..n {
                if present[node * MAX_VERTICES + neighbor] != 0 && !seen[neighbor] {
                    seen[neighbor] = true;
                    stack[size] = neighbor;
                    size += 1;
                }
            }
        }
    }
    count
}

fn prim_forest(n: usize, present: &[u8; 64], weights: &[i64; 64]) -> (usize, u32) {
    let mut in_forest = [false; MAX_VERTICES];
    let mut best_weight = [0_i64; MAX_VERTICES];
    let mut best_parent = [-1_i32; MAX_VERTICES];
    let mut components = 0;
    let mut mask = 0_u32;
    for root in 0..n {
        if in_forest[root] { continue; }
        components += 1;
        in_forest[root] = true;
        for neighbor in 0..n {
            let index = root * MAX_VERTICES + neighbor;
            if present[index] != 0 && !in_forest[neighbor] {
                best_weight[neighbor] = weights[index];
                best_parent[neighbor] = root as i32;
            }
        }
        loop {
            let mut selected = None;
            for candidate in 0..n {
                if in_forest[candidate] || best_parent[candidate] < 0 { continue; }
                if selected.map_or(true, |old: usize| best_weight[candidate] < best_weight[old]) {
                    selected = Some(candidate);
                }
            }
            let Some(node) = selected else { break; };
            let parent = best_parent[node] as usize;
            mask |= 1_u32 << edge_bit_index(n, parent, node);
            in_forest[node] = true;
            best_parent[node] = -1;
            for neighbor in 0..n {
                let index = node * MAX_VERTICES + neighbor;
                if present[index] != 0 && !in_forest[neighbor] &&
                    (best_parent[neighbor] < 0 || weights[index] < best_weight[neighbor]) {
                    best_weight[neighbor] = weights[index];
                    best_parent[neighbor] = node as i32;
                }
            }
        }
    }
    (components, mask)
}

fn find_root(parent: &mut [usize; MAX_VERTICES], mut node: usize) -> usize {
    while parent[node] != node {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    node
}

fn kruskal_forest(n: usize, present: &[u8; 64], weights: &[i64; 64]) -> (usize, u32) {
    let mut edges = [(0_i64, 0_usize, 0_usize); MAX_EDGES];
    let mut edge_count = 0;
    for u in 0..n {
        for v in u + 1..n {
            let index = u * MAX_VERTICES + v;
            if present[index] != 0 {
                edges[edge_count] = (weights[index], u, v);
                edge_count += 1;
            }
        }
    }
    edges[..edge_count].sort_by_key(|edge| edge.0);
    let mut parent = [0_usize; MAX_VERTICES];
    let mut rank = [0_u8; MAX_VERTICES];
    for (index, item) in parent.iter_mut().enumerate().take(n) { *item = index; }
    let mut components = n;
    let mut mask = 0_u32;
    for &(_weight, u, v) in &edges[..edge_count] {
        let left = find_root(&mut parent, u);
        let right = find_root(&mut parent, v);
        if left == right { continue; }
        if rank[left] < rank[right] { parent[left] = right; }
        else if rank[left] > rank[right] { parent[right] = left; }
        else { parent[right] = left; rank[left] += 1; }
        components -= 1;
        mask |= 1_u32 << edge_bit_index(n, u, v);
    }
    (components, mask)
}

#[no_mangle]
pub unsafe extern "C" fn undirected_graph(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(3..=MAX_INPUT_LENGTH).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n_value = values[0];
    let initial_count_value = values[1];
    if !(0..=MAX_VERTICES as i64).contains(&n_value) || !(0..=MAX_EDGES as i64).contains(&initial_count_value) {
        return -1;
    }
    let n = n_value as usize;
    let initial_count = initial_count_value as usize;
    if initial_count > n * n.saturating_sub(1) / 2 { return -1; }
    let count_position = 2 + 3 * initial_count;
    if count_position >= length { return -1; }
    let operation_count_value = values[count_position];
    if !(0..=MAX_OPERATIONS as i64).contains(&operation_count_value) ||
        length != 3 + 3 * initial_count + 4 * operation_count_value as usize { return -1; }

    let mut present = [0_u8; 64];
    let mut weights = [0_i64; 64];
    for edge in 0..initial_count {
        let position = 2 + 3 * edge;
        let u_value = values[position];
        let v_value = values[position + 1];
        let weight = values[position + 2];
        if u_value < 0 || u_value >= v_value || v_value >= n_value || !(MIN_WEIGHT..=MAX_WEIGHT).contains(&weight) {
            return -1;
        }
        let u = u_value as usize;
        let v = v_value as usize;
        if present[u * MAX_VERTICES + v] != 0 { return -1; }
        for first in 0..n {
            for second in first + 1..n {
                let index = first * MAX_VERTICES + second;
                if present[index] != 0 && weights[index] == weight { return -1; }
            }
        }
        present[u * MAX_VERTICES + v] = 1;
        present[v * MAX_VERTICES + u] = 1;
        weights[u * MAX_VERTICES + v] = weight;
        weights[v * MAX_VERTICES + u] = weight;
    }

    let mut hash = FNV_OFFSET;
    for operation in 0..operation_count_value as usize {
        let position = count_position + 1 + 4 * operation;
        let opcode = values[position];
        let u_value = values[position + 1];
        let v_value = values[position + 2];
        let weight = values[position + 3];
        let mut result_code = 0_u8;
        if opcode == 0 {
            if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value ||
                !(MIN_WEIGHT..=MAX_WEIGHT).contains(&weight) { return -1; }
            let u = u_value as usize;
            let v = v_value as usize;
            let index = u * MAX_VERTICES + v;
            let reverse = v * MAX_VERTICES + u;
            let old_index = if u < v { index } else { reverse };
            for first in 0..n {
                for second in first + 1..n {
                    let other = first * MAX_VERTICES + second;
                    if other != old_index && present[other] != 0 && weights[other] == weight { return -1; }
                }
            }
            present[index] = 1;
            present[reverse] = 1;
            weights[index] = weight;
            weights[reverse] = weight;
        } else if opcode == 1 || opcode == 2 {
            if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value || weight != 0 {
                return -1;
            }
            let u = u_value as usize;
            let v = v_value as usize;
            let index = u * MAX_VERTICES + v;
            let reverse = v * MAX_VERTICES + u;
            if opcode == 1 {
                present[index] = 0;
                present[reverse] = 0;
                weights[index] = 0;
                weights[reverse] = 0;
            } else { result_code = present[index]; }
        } else if opcode == 3 {
            if u_value != 0 || v_value != 0 || weight != 0 { return -1; }
            hash = hash_byte(hash, opcode as u8);
            hash = hash_byte(hash, result_code);
            hash = hash_byte(hash, component_count(n, &present) as u8);
            continue;
        } else if (4..=6).contains(&opcode) {
            if u_value != 0 || v_value != 0 || weight != 0 { return -1; }
            let (components, mask) = if opcode == 5 {
                kruskal_forest(n, &present, &weights)
            } else {
                prim_forest(n, &present, &weights)
            };
            hash = hash_byte(hash, opcode as u8);
            hash = hash_byte(hash, result_code);
            hash = hash_byte(hash, components as u8);
            hash = hash_u32(hash, mask);
            continue;
        } else { return -1; }
        hash = hash_byte(hash, opcode as u8);
        hash = hash_byte(hash, result_code);
    }

    let active_count = (0..n).flat_map(|u| (u + 1..n).map(move |v| (u, v)))
        .filter(|&(u, v)| present[u * MAX_VERTICES + v] != 0).count();
    hash = hash_byte(hash, n as u8);
    hash = hash_byte(hash, active_count as u8);
    for u in 0..n {
        for v in u + 1..n {
            if present[u * MAX_VERTICES + v] == 0 { continue; }
            hash = hash_byte(hash, u as u8);
            hash = hash_byte(hash, v as u8);
            hash = hash_i32(hash, weights[u * MAX_VERTICES + v]);
        }
    }
    (hash & RESULT_MASK) as i64
}
