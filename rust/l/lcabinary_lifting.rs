const MAX_NODES: usize = 128;
const MAX_QUERIES: usize = 256;
const MAX_LEVELS: usize = 7;
const MAX_VALID_INPUT_LENGTH: usize = 770;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 771;

fn lca(mut left: usize, mut right: usize, depth: &[usize; MAX_NODES], up: &[[usize; MAX_LEVELS]; MAX_NODES], levels: usize) -> usize {
    if depth[left] < depth[right] { std::mem::swap(&mut left, &mut right); }
    let mut difference = depth[left] - depth[right];
    let mut bit = 0;
    while difference > 0 {
        if difference & 1 != 0 { left = up[left][bit]; }
        difference >>= 1;
        bit += 1;
    }
    if left == right { return left; }
    for level in (0..levels).rev() {
        if up[left][level] != up[right][level] {
            left = up[left][level];
            right = up[right][level];
        }
    }
    up[left][0]
}

#[no_mangle]
pub unsafe extern "C" fn lca_binary_lifting_benchmark(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 2 || values[0] > MAX_NODES as i64 { return -1; }
    let node_count = values[0] as usize;
    if values[1] < 0 || values[1] >= node_count as i64 { return -1; }
    let root = values[1] as usize;
    if values[2] != node_count as i64 - 1 { return -1; }
    let edge_count = node_count - 1;
    let query_count_index = 3 + 2 * edge_count;
    if query_count_index >= length { return -1; }
    let query_count_value = values[query_count_index];
    if query_count_value < 0 || query_count_value > MAX_QUERIES as i64 { return -1; }
    let query_count = query_count_value as usize;
    if length != query_count_index + 1 + 2 * query_count || length > MAX_VALID_INPUT_LENGTH { return -1; }

    let mut adjacency = [[false; MAX_NODES]; MAX_NODES];
    for edge in 0..edge_count {
        let left_value = values[3 + 2 * edge];
        let right_value = values[4 + 2 * edge];
        if left_value < 0 || left_value >= node_count as i64 || right_value < 0 || right_value >= node_count as i64 || left_value == right_value { return -1; }
        let left = left_value as usize;
        let right = right_value as usize;
        if adjacency[left][right] { return -1; }
        adjacency[left][right] = true;
        adjacency[right][left] = true;
    }

    let mut parent = [0_usize; MAX_NODES];
    let mut depth = [0_usize; MAX_NODES];
    let mut visited = [false; MAX_NODES];
    let mut queue = [0_usize; MAX_NODES];
    let mut head = 0;
    let mut tail = 1;
    queue[0] = root;
    visited[root] = true;
    parent[root] = root;
    while head < tail {
        let node = queue[head];
        head += 1;
        for child in 0..node_count {
            if !adjacency[node][child] { continue; }
            if !visited[child] {
                visited[child] = true;
                parent[child] = node;
                depth[child] = depth[node] + 1;
                queue[tail] = child;
                tail += 1;
            } else if child != parent[node] { return -1; }
        }
    }
    if tail != node_count { return -1; }

    let mut levels = 1;
    while (1_usize << levels) < node_count { levels += 1; }
    let mut up = [[0_usize; MAX_LEVELS]; MAX_NODES];
    for node in 0..node_count { up[node][0] = parent[node]; }
    for level in 1..levels {
        for node in 0..node_count { up[node][level] = up[up[node][level - 1]][level - 1]; }
    }

    let mut checksum = 0_i64;
    let queries_start = query_count_index + 1;
    for query in 0..query_count {
        let left = values[queries_start + 2 * query];
        let right = values[queries_start + 2 * query + 1];
        if left < 0 || left >= node_count as i64 || right < 0 || right >= node_count as i64 { return -1; }
        let ancestor = lca(left as usize, right as usize, &depth, &up, levels);
        checksum += (query as i64 + 1) * (ancestor as i64 + 1);
    }
    checksum
}
