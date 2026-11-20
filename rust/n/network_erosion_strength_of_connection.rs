const MAX_VERTICES: usize = 8;
const MAX_PARSEABLE_INPUT: usize = 117;
const OUTPUT_BYTES: usize = 16;

fn shortest_path(adjacency: &[u16; MAX_VERTICES], n: usize, source: usize,
                 target: usize, path: &mut [usize; MAX_VERTICES]) -> usize {
    let mut distance = [-1i32; MAX_VERTICES];
    let mut predecessor = [usize::MAX; MAX_VERTICES];
    let mut queue = [0usize; MAX_VERTICES];
    let mut head = 0usize;
    let mut tail = 0usize;
    queue[tail] = source;
    tail += 1;
    distance[source] = 0;
    while head < tail {
        let vertex = queue[head];
        head += 1;
        for successor in 0..n {
            let bit = 1u16 << successor;
            if adjacency[vertex] & bit != 0 && distance[successor] == -1 {
                distance[successor] = distance[vertex] + 1;
                predecessor[successor] = vertex;
                queue[tail] = successor;
                tail += 1;
            }
        }
    }
    if distance[target] == -1 { return 0; }
    let mut reversed = [0usize; MAX_VERTICES];
    let mut count = 0usize;
    let mut vertex = target;
    loop {
        reversed[count] = vertex;
        count += 1;
        if vertex == source { break; }
        vertex = predecessor[vertex];
        if vertex == usize::MAX { return 0; }
    }
    for index in 0..count { path[index] = reversed[count - index - 1]; }
    count
}

fn gcd(mut left: i64, mut right: i64) -> i64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

unsafe fn write_i64(output: *mut u8, word: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        output.add(word * 8 + byte).write((bits >> (byte * 8)) as u8);
    }
}

#[no_mangle]
pub unsafe extern "C" fn network_erosion_strength_of_connection(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_PARSEABLE_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let vertex_raw = values[0];
    let edge_raw = values[1];
    let source_raw = values[2];
    let target_raw = values[3];
    if vertex_raw < 2 || vertex_raw > MAX_VERTICES as i64 || edge_raw < 0
        || edge_raw > vertex_raw * (vertex_raw - 1) || source_raw < 0
        || source_raw >= vertex_raw || target_raw < 0 || target_raw >= vertex_raw
        || source_raw == target_raw { return -1; }
    let n = vertex_raw as usize;
    let edge_count = edge_raw as usize;
    let source = source_raw as usize;
    let target = target_raw as usize;
    if length != 4 + 2 * edge_count { return -1; }

    let mut adjacency = [0u16; MAX_VERTICES];
    let mut cursor = 4usize;
    for _ in 0..edge_count {
        let from_raw = values[cursor];
        let to_raw = values[cursor + 1];
        cursor += 2;
        if from_raw < 0 || from_raw >= vertex_raw || to_raw < 0 || to_raw >= vertex_raw
            || from_raw == to_raw { return -1; }
        let from = from_raw as usize;
        let to = to_raw as usize;
        let bit = 1u16 << to;
        if adjacency[from] & bit != 0 { return -1; }
        adjacency[from] |= bit;
    }

    let mut distances = [-1i32; MAX_VERTICES];
    let mut path = [0usize; MAX_VERTICES];
    let first_count = shortest_path(&adjacency, n, source, target, &mut path);
    if first_count != 0 {
        let initial_length = (first_count - 1) as i32;
        distances[source] = initial_length;
        distances[target] = initial_length;
        loop {
            let path_count = shortest_path(&adjacency, n, source, target, &mut path);
            if path_count == 0 { break; }
            let path_length = (path_count - 1) as i32;
            if path_length == 1 {
                adjacency[source] &= !(1u16 << target);
                continue;
            }
            for index in 0..path_count {
                let vertex = path[index];
                if distances[vertex] == -1 { distances[vertex] = path_length; }
            }
            for index in 1..(path_count - 1) {
                let vertex = path[index];
                let bit = 1u16 << vertex;
                adjacency[vertex] = 0;
                for other in 0..n { adjacency[other] &= !bit; }
            }
        }
    }

    let mut reciprocal_sum_scaled = 0i64;
    for vertex in 0..n {
        if distances[vertex] >= 1 { reciprocal_sum_scaled += 420 / i64::from(distances[vertex]); }
    }
    let mut numerator = 2 * reciprocal_sum_scaled;
    let mut denominator = 420 * (n as i64 + 2);
    if numerator == 0 {
        denominator = 1;
    } else {
        let divisor = gcd(numerator, denominator);
        numerator /= divisor;
        denominator /= divisor;
    }
    if output.is_null() || capacity < OUTPUT_BYTES { return -2; }
    write_i64(output, 0, numerator);
    write_i64(output, 1, denominator);
    OUTPUT_BYTES as i64
}
