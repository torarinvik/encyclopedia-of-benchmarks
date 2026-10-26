const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 28;
const MAX_INPUT: usize = 66;
const MAX_FIELDS: usize = 73;
const MAX_OUTPUT_BYTES: usize = 8 * MAX_FIELDS;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

fn unique_shortest_paths(adjacency: &[bool; MAX_VERTICES * MAX_VERTICES], n: usize) -> bool {
    for source in 0..n {
        let mut distance = [-1i8; MAX_VERTICES];
        let mut ways = [0u8; MAX_VERTICES];
        let mut queue = [0usize; MAX_VERTICES];
        let mut head = 0;
        let mut tail = 0;
        distance[source] = 0; ways[source] = 1; queue[tail] = source; tail += 1;
        while head < tail {
            let vertex = queue[head]; head += 1;
            for neighbor in 0..n {
                if !adjacency[vertex * MAX_VERTICES + neighbor] { continue; }
                if distance[neighbor] < 0 {
                    distance[neighbor] = distance[vertex] + 1;
                    ways[neighbor] = ways[vertex];
                    queue[tail] = neighbor; tail += 1;
                } else if distance[neighbor] == distance[vertex] + 1 {
                    ways[neighbor] = (ways[neighbor] + ways[vertex]).min(2);
                }
            }
        }
        for vertex in 0..n { if ways[vertex] != 1 { return false; } }
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn hub_labeling_pruned(input: *const i64, length: usize,
                                               output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let values = core::slice::from_raw_parts(input, length);
    if values[0] < 1 || values[0] > MAX_VERTICES as i64
        || values[1] < 0 || values[1] > MAX_EDGES as i64 { return -1; }
    let n = values[0] as usize;
    let m = values[1] as usize;
    if length != 2 + n + 2 * m { return -1; }
    let mut seen_order = [false; MAX_VERTICES];
    for i in 0..n {
        let vertex = values[2 + i];
        if vertex < 0 || vertex >= n as i64 || seen_order[vertex as usize] { return -1; }
        seen_order[vertex as usize] = true;
    }
    let mut adjacency = [false; MAX_VERTICES * MAX_VERTICES];
    let mut previous_left = -1i64;
    let mut previous_right = -1i64;
    for edge in 0..m {
        let left = values[2 + n + 2 * edge];
        let right = values[3 + n + 2 * edge];
        if left < 0 || right <= left || right >= n as i64 || left < previous_left
            || (left == previous_left && right <= previous_right) { return -1; }
        previous_left = left; previous_right = right;
        adjacency[left as usize * MAX_VERTICES + right as usize] = true;
        adjacency[right as usize * MAX_VERTICES + left as usize] = true;
    }
    if !unique_shortest_paths(&adjacency, n) { return -1; }

    let mut labels = [[-1i16; MAX_VERTICES]; MAX_VERTICES];
    for order_index in 0..n {
        let hub = values[2 + order_index] as usize;
        let mut distance = [-1i8; MAX_VERTICES];
        let mut queue = [0usize; MAX_VERTICES];
        let mut head = 0;
        let mut tail = 0;
        distance[hub] = 0; queue[tail] = hub; tail += 1;
        while head < tail {
            let vertex = queue[head]; head += 1;
            let mut estimate = (2 * MAX_VERTICES) as i16;
            for common in 0..n {
                let from_hub = labels[hub][common];
                let from_vertex = labels[vertex][common];
                if from_hub >= 0 && from_vertex >= 0 && from_hub + from_vertex < estimate {
                    estimate = from_hub + from_vertex;
                }
            }
            if estimate <= distance[vertex] as i16 { continue; }
            labels[vertex][hub] = distance[vertex] as i16;
            for neighbor in 0..n {
                if adjacency[vertex * MAX_VERTICES + neighbor] && distance[neighbor] < 0 {
                    distance[neighbor] = distance[vertex] + 1;
                    queue[tail] = neighbor; tail += 1;
                }
            }
        }
    }
    let mut fields = [0i64; MAX_FIELDS];
    let mut field_count = 0;
    fields[field_count] = n as i64; field_count += 1;
    for vertex in 0..n {
        let count_index = field_count; field_count += 1;
        let mut count = 0i64;
        for hub in 0..n {
            let value = labels[vertex][hub];
            if value >= 0 {
                fields[field_count] = hub as i64 | ((value as i64) << 8);
                field_count += 1; count += 1;
            }
        }
        fields[count_index] = count;
    }
    let bytes = field_count * 8;
    if output.is_null() || capacity < bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    for i in 0..field_count { store_i64_le(staged.as_mut_ptr(), 8 * i, fields[i]); }
    for i in 0..bytes { *output.add(i) = staged[i]; }
    bytes as i64
}
