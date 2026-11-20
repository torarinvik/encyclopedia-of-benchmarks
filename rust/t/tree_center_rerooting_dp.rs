const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + 2 * (MAX_N - 1);

fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn tree_center_rerooting_dp(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    if n_value < 1 || n_value > MAX_N as i64 { return -1; }
    let n = n_value as usize;
    if length != 1 + 2 * (n - 1) { return -1; }

    let mut adjacency = [[0usize; MAX_N]; MAX_N];
    let mut degree = [0usize; MAX_N];
    for edge in 0..n - 1 {
        let offset = 1 + 2 * edge;
        let (left_value, right_value) = (values[offset], values[offset + 1]);
        if left_value < 0 || left_value >= n_value || right_value < 0 ||
            right_value >= n_value || left_value == right_value { return -1; }
        let (left, right) = (left_value as usize, right_value as usize);
        adjacency[left][degree[left]] = right;
        degree[left] += 1;
        adjacency[right][degree[right]] = left;
        degree[right] += 1;
    }

    let mut parent = [MAX_N; MAX_N];
    let mut order = [0usize; MAX_N];
    parent[0] = MAX_N + 1;
    let mut order_count = 1usize;
    let mut position = 0usize;
    while position < order_count {
        let vertex = order[position];
        for &child in &adjacency[vertex][..degree[vertex]] {
            if child == parent[vertex] { continue; }
            if parent[child] != MAX_N { return -1; }
            parent[child] = vertex;
            order[order_count] = child;
            order_count += 1;
        }
        position += 1;
    }
    if order_count != n { return -1; }

    let mut down = [0usize; MAX_N];
    let mut best = [0usize; MAX_N];
    let mut second = [0usize; MAX_N];
    let mut best_child = [MAX_N; MAX_N];
    for position in (0..n).rev() {
        let vertex = order[position];
        for &child in &adjacency[vertex][..degree[vertex]] {
            if parent[child] != vertex { continue; }
            let branch = down[child] + 1;
            if branch > best[vertex] {
                second[vertex] = best[vertex];
                best[vertex] = branch;
                best_child[vertex] = child;
            } else if branch > second[vertex] {
                second[vertex] = branch;
            }
        }
        down[vertex] = best[vertex];
    }

    let mut outside = [-1isize; MAX_N];
    for &vertex in &order[..n] {
        for &child in &adjacency[vertex][..degree[vertex]] {
            if parent[child] != vertex { continue; }
            let sibling = if best_child[vertex] == child { second[vertex] } else { best[vertex] };
            outside[child] = (outside[vertex].max(sibling as isize)) + 1;
        }
    }
    let radius = (0..n)
        .map(|v| down[v].max(outside[v].max(0) as usize))
        .min()
        .unwrap_or(0);
    let centers: Vec<i64> = (0..n)
        .filter(|&v| down[v].max(outside[v].max(0) as usize) == radius)
        .map(|v| v as i64)
        .collect();
    let required = centers.len() * 8;
    if output.is_null() || capacity < required { return -2; }
    let encoded = std::slice::from_raw_parts_mut(output, required);
    for (index, &center) in centers.iter().enumerate() { store_i64_le(encoded, index * 8, center); }
    required as i64
}
