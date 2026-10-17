const MAX_VERTICES: usize = 64;
const MAX_EDGES: usize = 4096;
const MAX_INPUT_LENGTH: usize = 2 + 3 * MAX_EDGES;

fn find_root(parent: &mut [usize; MAX_VERTICES], node_start: usize) -> usize {
    let mut node = node_start;
    while parent[node] != node {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    node
}

unsafe fn put_i64_le(output: *mut u8, offset: usize, value: i64) {
    std::ptr::copy_nonoverlapping(value.to_le_bytes().as_ptr(), output.add(offset), 8);
}

#[no_mangle]
pub unsafe extern "C" fn minimum_spanning_tree_kruskal(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let raw_vertices = values[0];
    let raw_edges = values[1];
    if !(0..=MAX_VERTICES as i64).contains(&raw_vertices)
        || !(0..=MAX_EDGES as i64).contains(&raw_edges)
    {
        return -1;
    }
    let vertex_count = raw_vertices as usize;
    let edge_count = raw_edges as usize;
    if length != 2 + 3 * edge_count {
        return -1;
    }

    let mut order = [0usize; MAX_EDGES];
    for index in 0..edge_count {
        let offset = 2 + 3 * index;
        let left = values[offset];
        let right = values[offset + 1];
        if left < 0 || left >= raw_vertices || right < 0 || right >= raw_vertices {
            return -1;
        }
        order[index] = index;
    }
    order[..edge_count].sort_by_key(|&index| (values[2 + 3 * index + 2], index));

    let mut parent = [0usize; MAX_VERTICES];
    for vertex in 0..vertex_count {
        parent[vertex] = vertex;
    }
    let mut accepted = [0usize; MAX_VERTICES];
    let mut accepted_count = 0usize;
    for &index in &order[..edge_count] {
        let offset = 2 + 3 * index;
        let left_root = find_root(&mut parent, values[offset] as usize);
        let right_root = find_root(&mut parent, values[offset + 1] as usize);
        if left_root != right_root {
            accepted[accepted_count] = index;
            accepted_count += 1;
            parent[left_root] = right_root;
        }
    }

    let byte_count = accepted_count * 24;
    if output.is_null() || capacity < byte_count {
        return -2;
    }
    for (result_index, &edge_index) in accepted[..accepted_count].iter().enumerate() {
        let input_offset = 2 + 3 * edge_index;
        let output_offset = 24 * result_index;
        put_i64_le(output, output_offset, values[input_offset]);
        put_i64_le(output, output_offset + 8, values[input_offset + 1]);
        put_i64_le(output, output_offset + 16, values[input_offset + 2]);
    }
    byte_count as i64
}
