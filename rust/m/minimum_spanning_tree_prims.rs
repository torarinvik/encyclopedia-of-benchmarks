const MAX_VERTICES: usize = 16;
const MAX_EDGES: usize = 64;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 2 + 3 * MAX_EDGES + 1;
const MAX_OUTPUT_WORDS: usize = 1 + 2 * (MAX_VERTICES - 1);
const MAX_OUTPUT_BYTES: usize = 4 * MAX_OUTPUT_WORDS;
const SOURCE_HEAP_SENTINEL: i64 = i64::MAX;

fn top_to_bottom(
    heap: &mut [i64; MAX_VERTICES],
    positions: &mut [i32; MAX_VERTICES],
    node_position: &mut [i32; MAX_VERTICES],
    size: usize,
    start: usize,
) {
    let mut root = start;
    while root * 2 + 1 < size {
        let left = root * 2 + 1;
        let right = left + 1;
        let child = if right >= size || heap[left] < heap[right] { left } else { right };
        if heap[child] >= heap[root] {
            break;
        }
        heap.swap(root, child);
        positions.swap(root, child);
        node_position[positions[root] as usize] = root as i32;
        node_position[positions[child] as usize] = child as i32;
        root = child;
    }
}

fn decrease_key(
    value: i64,
    mut index: usize,
    heap: &mut [i64; MAX_VERTICES],
    positions: &mut [i32; MAX_VERTICES],
    node_position: &mut [i32; MAX_VERTICES],
) {
    let vertex = positions[index];
    while index != 0 {
        let parent = (index - 1) / 2;
        if value < heap[parent] {
            heap[index] = heap[parent];
            positions[index] = positions[parent];
            node_position[positions[parent] as usize] = index as i32;
        } else {
            heap[index] = value;
            positions[index] = vertex;
            node_position[vertex as usize] = index as i32;
            return;
        }
        index = parent;
    }
    heap[0] = value;
    positions[0] = vertex;
    node_position[vertex as usize] = 0;
}

fn put_i32_le(output: &mut [u8; MAX_OUTPUT_BYTES], offset: usize, value: i32) {
    output[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn minimum_spanning_tree_prims(
    input: *const i32,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let raw_vertices = values[0];
    let raw_edges = values[1];
    if !(1..=MAX_VERTICES as i32).contains(&raw_vertices)
        || !(0..=MAX_EDGES as i32).contains(&raw_edges)
    {
        return -1;
    }
    let vertex_count = raw_vertices as usize;
    let edge_count = raw_edges as usize;
    if length != 2 + 3 * edge_count {
        return -1;
    }

    let mut neighbors = [[0i32; MAX_VERTICES]; MAX_VERTICES];
    let mut weights = [[0i32; MAX_VERTICES]; MAX_VERTICES];
    let mut degree = [0usize; MAX_VERTICES];
    let mut seen = [[false; MAX_VERTICES]; MAX_VERTICES];
    for index in 0..edge_count {
        let offset = 2 + 3 * index;
        let u = values[offset];
        let v = values[offset + 1];
        let weight = values[offset + 2];
        if u < 0 || v <= u || v >= raw_vertices || seen[u as usize][v as usize] {
            return -1;
        }
        seen[u as usize][v as usize] = true;
        let u_degree = degree[u as usize];
        neighbors[u as usize][u_degree] = v;
        weights[u as usize][u_degree] = weight;
        degree[u as usize] += 1;
        let v_degree = degree[v as usize];
        neighbors[v as usize][v_degree] = u;
        weights[v as usize][v_degree] = weight;
        degree[v as usize] += 1;
    }

    if vertex_count > 1 {
        let mut reached_vertex = [false; MAX_VERTICES];
        let mut stack = [0usize; MAX_VERTICES];
        let mut stack_size = 1usize;
        let mut reached = 0usize;
        stack[0] = 0;
        reached_vertex[0] = true;
        while stack_size > 0 {
            stack_size -= 1;
            let vertex = stack[stack_size];
            reached += 1;
            for i in 0..degree[vertex] {
                let neighbor = neighbors[vertex][i] as usize;
                if !reached_vertex[neighbor] {
                    reached_vertex[neighbor] = true;
                    stack[stack_size] = neighbor;
                    stack_size += 1;
                }
            }
        }
        if reached != vertex_count {
            return -1;
        }
    }

    let mut visited = [false; MAX_VERTICES];
    let mut parent = [-1i32; MAX_VERTICES];
    let mut heap = [SOURCE_HEAP_SENTINEL; MAX_VERTICES];
    let mut positions = [0i32; MAX_VERTICES];
    let mut node_position = [0i32; MAX_VERTICES];
    for vertex in 0..vertex_count {
        positions[vertex] = vertex as i32;
        node_position[vertex] = vertex as i32;
    }
    visited[0] = true;
    for i in 0..degree[0] {
        let neighbor = neighbors[0][i] as usize;
        parent[neighbor] = 0;
        heap[neighbor] = weights[0][i] as i64;
    }
    for start in (0..vertex_count / 2).rev() {
        top_to_bottom(&mut heap, &mut positions, &mut node_position, vertex_count, start);
    }

    let mut words = [0i32; MAX_OUTPUT_WORDS];
    let mut word_count = 1usize;
    let mut tree_edge_count = 0usize;
    for _step in 1..vertex_count {
        let vertex = positions[0] as usize;
        heap[0] = SOURCE_HEAP_SENTINEL;
        top_to_bottom(&mut heap, &mut positions, &mut node_position, vertex_count, 0);
        if !visited[vertex] {
            words[word_count] = parent[vertex];
            words[word_count + 1] = vertex as i32;
            word_count += 2;
            tree_edge_count += 1;
            visited[vertex] = true;
            for i in 0..degree[vertex] {
                let neighbor = neighbors[vertex][i] as usize;
                let weight = weights[vertex][i] as i64;
                if !visited[neighbor] {
                    let heap_index = node_position[neighbor] as usize;
                    if weight < heap[heap_index] {
                        heap[heap_index] = weight;
                        decrease_key(weight, heap_index, &mut heap, &mut positions, &mut node_position);
                        parent[neighbor] = vertex as i32;
                    }
                }
            }
        }
    }
    if tree_edge_count != vertex_count - 1 {
        return -1;
    }
    words[0] = tree_edge_count as i32;
    let byte_count = word_count * 4;
    if byte_count > MAX_OUTPUT_BYTES || output.is_null() || capacity < byte_count {
        return -2;
    }
    let mut buffer = [0u8; MAX_OUTPUT_BYTES];
    for index in 0..word_count {
        put_i32_le(&mut buffer, index * 4, words[index]);
    }
    std::ptr::copy_nonoverlapping(buffer.as_ptr(), output, byte_count);
    byte_count as i64
}
