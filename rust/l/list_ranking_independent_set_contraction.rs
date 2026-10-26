const MAX_N: usize = 16;
const MAX_INPUT: usize = 34;
const MAX_OUTPUT: usize = 128;

unsafe fn put64(output: *mut u8, position: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(position + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn list_ranking_independent_set_contraction(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let head64 = *input.add(1);
    if n64 < 1 || n64 > MAX_N as i64 || length != 2 + 2 * n64 as usize ||
        head64 < 0 || head64 >= n64 { return -1; }
    let n = n64 as usize;
    let head = head64 as usize;
    let mut weight = [0i64; MAX_N];
    let mut successor = [0i64; MAX_N];
    let mut indegree = [0usize; MAX_N];
    let mut tail_count = 0usize;
    for node in 0..n {
        weight[node] = *input.add(2 + node);
        successor[node] = *input.add(2 + n + node);
        if weight[node] < 1 || weight[node] > 10000 ||
            successor[node] < -1 || successor[node] >= n64 { return -1; }
        if successor[node] == -1 { tail_count += 1; }
        else {
            let next = successor[node] as usize;
            indegree[next] += 1;
            if indegree[next] > 1 { return -1; }
        }
    }
    if tail_count != 1 || indegree[head] != 0 { return -1; }

    let mut path = [0usize; MAX_N];
    let mut seen = [false; MAX_N];
    let mut path_length = 0usize;
    let mut node = head64;
    while node != -1 {
        let index = node as usize;
        if seen[index] || path_length == n { return -1; }
        seen[index] = true;
        path[path_length] = index;
        path_length += 1;
        node = successor[index];
    }
    if path_length != n { return -1; }
    let output_bytes = 8 * n;
    if output.is_null() || capacity < output_bytes { return -2; }

    let mut removed_node = [0usize; MAX_N];
    let mut removed_successor = [0usize; MAX_N];
    let mut old_successor_weight = [0i64; MAX_N];
    let mut removed_count = 0usize;
    while path_length > 1 {
        let mut counts = [0usize; 3];
        for position in 0..path_length - 1 { counts[position % 3] += 1; }
        let mut color = 0usize;
        for candidate in 1..3 {
            if counts[candidate] > counts[color] { color = candidate; }
        }
        let mut write = 0usize;
        for position in 0..path_length {
            let current = path[position];
            if position + 1 < path_length && position % 3 == color {
                let next = path[position + 1];
                removed_node[removed_count] = current;
                removed_successor[removed_count] = next;
                old_successor_weight[removed_count] = weight[next];
                removed_count += 1;
                weight[next] += weight[current];
            } else {
                path[write] = current;
                write += 1;
            }
        }
        if write == path_length { return -1; }
        path_length = write;
    }

    let mut rank = [0i64; MAX_N];
    rank[path[0]] = weight[path[0]];
    while removed_count > 0 {
        removed_count -= 1;
        let current = removed_node[removed_count];
        let next = removed_successor[removed_count];
        rank[current] = rank[next] - old_successor_weight[removed_count];
    }
    let mut staged = [0u8; MAX_OUTPUT];
    for index in 0..n { put64(staged.as_mut_ptr(), 8 * index, rank[index]); }
    for index in 0..output_bytes { *output.add(index) = staged[index]; }
    output_bytes as i64
}
