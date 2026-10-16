const MAX_VERTICES: usize = 32;
const MAX_EDGE_PAIRS: usize = 512;
const MAX_VALIDATION_LENGTH: usize = 2 + 2 * MAX_EDGE_PAIRS + 1;
const OUTPUT_BYTES_PER_VERTEX: usize = 8;

fn vertex_bit(vertex: usize) -> u64 {
    1u64 << vertex
}

#[no_mangle]
pub unsafe extern "C" fn welsh_powell(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_VALIDATION_LENGTH {
        return -1;
    }
    let n64 = *input;
    let edge_count64 = *input.add(1);
    if !(0..=MAX_VERTICES as i64).contains(&n64)
        || !(0..=MAX_EDGE_PAIRS as i64).contains(&edge_count64)
    {
        return -1;
    }
    let n = n64 as usize;
    let edge_count = edge_count64 as usize;
    if length != 2 + 2 * edge_count {
        return -1;
    }

    let mut adjacency = [0u64; MAX_VERTICES];
    for edge in 0..edge_count {
        let left64 = *input.add(2 + 2 * edge);
        let right64 = *input.add(3 + 2 * edge);
        if left64 < 0 || left64 >= n64 || right64 < 0 || right64 >= n64 || left64 == right64 {
            return -1;
        }
        let left = left64 as usize;
        let right = right64 as usize;
        adjacency[left] |= vertex_bit(right);
        adjacency[right] |= vertex_bit(left);
    }

    let output_bytes = n * OUTPUT_BYTES_PER_VERTEX;
    if output.is_null() || capacity < output_bytes {
        return -2;
    }

    let mut degrees = [0usize; MAX_VERTICES];
    let mut order = [0usize; MAX_VERTICES];
    let mut colors = [-1i64; MAX_VERTICES];
    for vertex in 0..n {
        order[vertex] = vertex;
        for neighbor in 0..n {
            if adjacency[vertex] & vertex_bit(neighbor) != 0 {
                degrees[vertex] += 1;
            }
        }
    }

    // Stable descending degree order keeps equal-degree vertices by index.
    for index in 1..n {
        let key = order[index];
        let mut position = index;
        while position > 0 && degrees[order[position - 1]] < degrees[key] {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = key;
    }

    let mut colored_vertices = 0u64;
    for index in 0..n {
        let vertex = order[index];
        if colors[vertex] >= 0 {
            continue;
        }

        let mut used_colors = 0u64;
        for neighbor in 0..n {
            if adjacency[vertex] & vertex_bit(neighbor) != 0 && colors[neighbor] >= 0 {
                used_colors |= vertex_bit(colors[neighbor] as usize);
            }
        }
        let mut color = 0usize;
        while used_colors & vertex_bit(color) != 0 {
            color += 1;
        }
        colors[vertex] = color as i64;
        colored_vertices |= vertex_bit(vertex);

        for other_index in 0..n {
            let other = order[other_index];
            if colors[other] < 0 && adjacency[other] & colored_vertices == 0 {
                colors[other] = color as i64;
                colored_vertices |= vertex_bit(other);
            }
        }
    }

    for vertex in 0..n {
        let bytes = colors[vertex].to_le_bytes();
        for byte in 0..OUTPUT_BYTES_PER_VERTEX {
            *output.add(vertex * OUTPUT_BYTES_PER_VERTEX + byte) = bytes[byte];
        }
    }
    output_bytes as i64
}
