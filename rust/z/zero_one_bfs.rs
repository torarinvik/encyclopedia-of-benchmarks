/// 0-1 BFS over a bounded directed graph encoded as weighted edge triples.
#[no_mangle]
pub extern "C" fn zero_one_bfs(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 3 || length > 3075 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values[0] < 1 || values[0] > 64 || values[2] < 0 || values[2] > 1024 { return -1; }
    let vertices = values[0] as usize;
    let source_value = values[1];
    let edge_count = values[2] as usize;
    if source_value < 0 || source_value as u64 >= vertices as u64 || length != 3 + 3 * edge_count {
        return -1;
    }
    let source = source_value as usize;

    let mut zero_edges = [0u64; 64];
    let mut one_edges = [0u64; 64];
    let mut distance = [u8::MAX; 64];
    let mut deque = [0u8; 4097];
    for edge in 0..edge_count {
        let origin_value = values[3 + 3 * edge];
        let destination_value = values[4 + 3 * edge];
        let weight = values[5 + 3 * edge];
        if origin_value < 0 || destination_value < 0 ||
            origin_value as u64 >= vertices as u64 || destination_value as u64 >= vertices as u64 ||
            (weight != 0 && weight != 1) {
            return -1;
        }
        let origin = origin_value as usize;
        let destination = destination_value as usize;
        let mask = 1u64 << destination;
        if weight == 0 { zero_edges[origin] |= mask; }
        else { one_edges[origin] |= mask; }
    }
    if output_capacity < vertices || (vertices != 0 && output.is_null()) { return -2; }

    let mut head = 0usize;
    let mut tail = 1usize;
    let mut queued = 1usize;
    deque[0] = source as u8;
    distance[source] = 0;
    while queued != 0 {
        let origin = deque[head] as usize;
        head = (head + 1) % 4097;
        queued -= 1;
        let base = distance[origin];
        for destination in 0..vertices {
            let mask = 1u64 << destination;
            if zero_edges[origin] & mask != 0 && base < distance[destination] {
                distance[destination] = base;
                head = if head == 0 { 4096 } else { head - 1 };
                deque[head] = destination as u8;
                queued += 1;
            }
            let candidate = base + 1;
            if one_edges[origin] & mask != 0 && candidate < distance[destination] {
                distance[destination] = candidate;
                deque[tail] = destination as u8;
                tail = (tail + 1) % 4097;
                queued += 1;
            }
        }
    }

    for vertex in 0..vertices {
        unsafe { *output.add(vertex) = distance[vertex]; }
    }
    vertices as i64
}
