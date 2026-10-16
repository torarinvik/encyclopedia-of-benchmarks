fn put(output: &mut [u8], word: usize, value: i64) {
    output[word * 8..word * 8 + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn depth_first_search_iterative_order(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n_value, edge_value) = (values[0], values[1]);
    if !(1..=10).contains(&n_value) || !(0..=64).contains(&edge_value)
        || length != 3 + 2 * edge_value as usize { return -1; }
    let n = n_value as usize;
    let edge_count = edge_value as usize;
    let mut adjacency = [[0usize; 128]; 11];
    let mut degree = [0usize; 11];
    let mut position = 2;
    for _ in 0..edge_count {
        let (left_value, right_value) = (values[position], values[position + 1]);
        position += 2;
        if !(1..=n_value).contains(&left_value) || !(1..=n_value).contains(&right_value) { return -1; }
        let (left, right) = (left_value as usize, right_value as usize);
        adjacency[left][degree[left]] = right;
        degree[left] += 1;
        adjacency[right][degree[right]] = left;
        degree[right] += 1;
    }
    let start_value = values[position];
    if !(1..=n_value).contains(&start_value) { return -1; }
    let start = start_value as usize;
    let mut visited = [false; 11];
    let mut stack = [0usize; 10];
    let mut order = [0usize; 10];
    visited[start] = true;
    let (mut stack_size, mut order_count) = (1, 0);
    stack[0] = start;
    while stack_size > 0 {
        stack_size -= 1;
        let vertex = stack[stack_size];
        order[order_count] = vertex;
        order_count += 1;
        for edge in 0..degree[vertex] {
            let neighbor = adjacency[vertex][edge];
            if !visited[neighbor] {
                visited[neighbor] = true;
                stack[stack_size] = neighbor;
                stack_size += 1;
            }
        }
    }
    let words = order_count + 1;
    if output.is_null() || capacity < words * 8 { return -2; }
    let destination = std::slice::from_raw_parts_mut(output, words * 8);
    put(destination, 0, order_count as i64);
    for index in 0..order_count { put(destination, index + 1, order[index] as i64); }
    (words * 8) as i64
}
