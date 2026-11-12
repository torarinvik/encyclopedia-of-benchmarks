const MAX_N: usize = 64;
const MAX_Q: usize = 64;
const MAX_LEVELS: usize = 7;
const MAX_INPUT_VALUES: usize = 2 + 2 * (MAX_N - 1) + 3 * MAX_Q;

fn find_root(parent: &mut [usize; MAX_N], mut item: usize) -> usize {
    while parent[item] != item {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    item
}

fn lift(ancestors: &[[usize; MAX_LEVELS]; MAX_N], mut vertex: usize, distance: usize) -> usize {
    for bit in 0..MAX_LEVELS {
        if (distance >> bit) & 1 != 0 {
            vertex = ancestors[vertex][bit];
        }
    }
    vertex
}

fn lowest_common_ancestor(
    ancestors: &[[usize; MAX_LEVELS]; MAX_N],
    depth: &[usize; MAX_N],
    mut left: usize,
    mut right: usize,
) -> usize {
    if depth[left] < depth[right] {
        std::mem::swap(&mut left, &mut right);
    }
    left = lift(ancestors, left, depth[left] - depth[right]);
    if left == right {
        return left;
    }
    for level in (0..MAX_LEVELS).rev() {
        if ancestors[left][level] != ancestors[right][level] {
            left = ancestors[left][level];
            right = ancestors[right][level];
        }
    }
    ancestors[left][0]
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn jump_on_tree(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_VALUES {
        return -1;
    }
    let n_value = *input;
    let q_value = *input.add(1);
    if n_value < 2 || n_value > MAX_N as i64 || q_value < 1 || q_value > MAX_Q as i64 {
        return -1;
    }
    let n = n_value as usize;
    let q = q_value as usize;
    let query_start = 2 + 2 * (n - 1);
    if length != query_start + 3 * q {
        return -1;
    }

    let mut adjacent = [[false; MAX_N]; MAX_N];
    let mut dsu_parent = [0usize; MAX_N];
    let mut dsu_size = [0usize; MAX_N];
    for vertex in 0..n {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    for edge in 0..(n - 1) {
        let offset = 2 + 2 * edge;
        let left_value = *input.add(offset);
        let right_value = *input.add(offset + 1);
        if left_value < 0 || left_value >= n_value || right_value < 0 ||
            right_value >= n_value || left_value == right_value {
            return -1;
        }
        let left = left_value as usize;
        let right = right_value as usize;
        let mut root_left = find_root(&mut dsu_parent, left);
        let mut root_right = find_root(&mut dsu_parent, right);
        if root_left == root_right {
            return -1;
        }
        if dsu_size[root_left] < dsu_size[root_right] {
            std::mem::swap(&mut root_left, &mut root_right);
        }
        dsu_parent[root_right] = root_left;
        dsu_size[root_left] += dsu_size[root_right];
        adjacent[left][right] = true;
        adjacent[right][left] = true;
    }

    let mut ancestors = [[0usize; MAX_LEVELS]; MAX_N];
    let mut depth = [0usize; MAX_N];
    let mut visited = [false; MAX_N];
    let mut stack = [0usize; MAX_N];
    let mut top = 1usize;
    stack[0] = 0;
    visited[0] = true;
    while top > 0 {
        top -= 1;
        let vertex = stack[top];
        for neighbor in 0..n {
            if !adjacent[vertex][neighbor] || visited[neighbor] {
                continue;
            }
            visited[neighbor] = true;
            ancestors[neighbor][0] = vertex;
            depth[neighbor] = depth[vertex] + 1;
            stack[top] = neighbor;
            top += 1;
        }
    }
    for level in 1..MAX_LEVELS {
        for vertex in 0..n {
            ancestors[vertex][level] = ancestors[ancestors[vertex][level - 1]][level - 1];
        }
    }

    let mut answers = [0i64; MAX_Q];
    for query in 0..q {
        let offset = query_start + 3 * query;
        let start_value = *input.add(offset);
        let target_value = *input.add(offset + 1);
        let index_value = *input.add(offset + 2);
        if start_value < 0 || start_value >= n_value || target_value < 0 ||
            target_value >= n_value || index_value < 0 || index_value >= n_value {
            return -1;
        }
        let start = start_value as usize;
        let target = target_value as usize;
        let index = index_value as usize;
        let common = lowest_common_ancestor(&ancestors, &depth, start, target);
        let upward = depth[start] - depth[common];
        let path_length = upward + depth[target] - depth[common];
        answers[query] = if index > path_length {
            -1
        } else if index <= upward {
            lift(&ancestors, start, index) as i64
        } else {
            lift(&ancestors, target, path_length - index) as i64
        };
    }

    let required = 8 * q;
    if output.is_null() || capacity < required {
        return -2;
    }
    for query in 0..q {
        store_i64_le(output, 8 * query, answers[query]);
    }
    required as i64
}
