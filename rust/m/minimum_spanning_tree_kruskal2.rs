const MAX_VERTICES: usize = 16;
const MAX_EDGES: usize = 64;
const MAX_INPUT_WORDS: usize = 194;
const MAX_OUTPUT_WORDS: usize = 1 + 3 * (MAX_VERTICES - 1);

#[derive(Clone, Copy)]
struct Edge { u: i32, v: i32, weight: i32 }

fn find_root(parent: &mut [i32; MAX_VERTICES], mut node: i32) -> i32 {
    while parent[node as usize] != node {
        let index = node as usize;
        parent[index] = parent[parent[index] as usize];
        node = parent[index];
    }
    node
}

fn put_i32_le(output: &mut [u8], offset: usize, value: i32) {
    output[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn minimum_spanning_tree_kruskal2(
    input: *const i32, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_WORDS { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let vertex_count = values[0];
    let edge_count = values[1];
    if !(1..=MAX_VERTICES as i32).contains(&vertex_count) ||
        !(0..=MAX_EDGES as i32).contains(&edge_count) ||
        length != 2 + 3 * edge_count as usize { return -1; }

    let mut input_edges = [Edge { u: 0, v: 0, weight: 0 }; MAX_EDGES];
    let mut seen = [[false; MAX_VERTICES]; MAX_VERTICES];
    let mut pos = 2usize;
    for i in 0..edge_count as usize {
        let u = values[pos];
        let v = values[pos + 1];
        let weight = values[pos + 2];
        pos += 3;
        if u < 0 || v <= u || v >= vertex_count || seen[u as usize][v as usize] { return -1; }
        seen[u as usize][v as usize] = true;
        input_edges[i] = Edge { u, v, weight };
    }

    let mut visited = [false; MAX_VERTICES];
    let mut stack = [0usize; MAX_VERTICES];
    let mut stack_size = 1usize;
    let mut reached = 0usize;
    stack[0] = 0;
    visited[0] = true;
    while stack_size > 0 {
        stack_size -= 1;
        let node = stack[stack_size];
        reached += 1;
        for neighbor in 0..vertex_count as usize {
            if (seen[node][neighbor] || seen[neighbor][node]) && !visited[neighbor] {
                visited[neighbor] = true;
                stack[stack_size] = neighbor;
                stack_size += 1;
            }
        }
    }
    if reached != vertex_count as usize { return -1; }

    let mut ordered = [Edge { u: 0, v: 0, weight: 0 }; MAX_EDGES];
    let mut ordered_count = 0usize;
    for u in 0..vertex_count {
        for i in 0..edge_count as usize {
            if input_edges[i].u == u {
                ordered[ordered_count] = input_edges[i];
                ordered_count += 1;
            }
        }
    }
    for i in 1..ordered_count {
        let key = ordered[i];
        let mut j = i;
        while j > 0 && ordered[j - 1].weight > key.weight {
            ordered[j] = ordered[j - 1];
            j -= 1;
        }
        ordered[j] = key;
    }

    let mut parent = [0i32; MAX_VERTICES];
    let mut rank = [0i32; MAX_VERTICES];
    for i in 0..vertex_count as usize { parent[i] = i as i32; }
    let mut words = [0i32; MAX_OUTPUT_WORDS];
    let mut word_count = 1usize;
    let mut accepted = 0usize;
    for edge in ordered.iter().take(ordered_count) {
        if accepted == vertex_count as usize - 1 { break; }
        let root_u = find_root(&mut parent, edge.u);
        let root_v = find_root(&mut parent, edge.v);
        if root_u == root_v { continue; }
        if rank[root_u as usize] < rank[root_v as usize] { parent[root_u as usize] = root_v; }
        else if rank[root_u as usize] > rank[root_v as usize] { parent[root_v as usize] = root_u; }
        else {
            parent[root_u as usize] = root_v;
            rank[root_v as usize] += 1;
        }
        words[word_count] = edge.u;
        words[word_count + 1] = edge.v;
        words[word_count + 2] = edge.weight;
        word_count += 3;
        accepted += 1;
    }
    if accepted != vertex_count as usize - 1 { return -1; }
    words[0] = accepted as i32;
    let bytes = word_count * 4;
    if output.is_null() || capacity < bytes { return -2; }
    let mut buffer = [0u8; MAX_OUTPUT_WORDS * 4];
    for i in 0..word_count { put_i32_le(&mut buffer, i * 4, words[i]); }
    std::ptr::copy_nonoverlapping(buffer.as_ptr(), output, bytes);
    bytes as i64
}
