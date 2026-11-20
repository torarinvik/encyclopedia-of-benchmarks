const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + 2 * (MAX_N - 1);
const MATRIX_CELLS: usize = MAX_N * MAX_N;

fn find_root(parent: &mut [usize; MAX_N], mut item: usize) -> usize {
    while parent[item] != item {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    item
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn tree_center(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let n_value = *input;
    if n_value < 1 || n_value > MAX_N as i64 {
        return -1;
    }
    let n = n_value as usize;
    if length != 1 + 2 * (n - 1) {
        return -1;
    }

    let mut adjacency = [0usize; MATRIX_CELLS];
    let mut adjacency_count = [0usize; MAX_N];
    let mut degree = [0usize; MAX_N];
    let mut parent = [0usize; MAX_N];
    let mut component_size = [0usize; MAX_N];
    for vertex in 0..n {
        parent[vertex] = vertex;
        component_size[vertex] = 1;
    }
    for edge in 0..n - 1 {
        let offset = 1 + 2 * edge;
        let left_value = *input.add(offset);
        let right_value = *input.add(offset + 1);
        if left_value < 0 || left_value >= n_value || right_value < 0 ||
            right_value >= n_value || left_value == right_value {
            return -1;
        }
        let left = left_value as usize;
        let right = right_value as usize;
        let mut root_left = find_root(&mut parent, left);
        let mut root_right = find_root(&mut parent, right);
        if root_left == root_right {
            return -1;
        }
        if component_size[root_left] < component_size[root_right] {
            std::mem::swap(&mut root_left, &mut root_right);
        }
        parent[root_right] = root_left;
        component_size[root_left] += component_size[root_right];
        adjacency[left * MAX_N + adjacency_count[left]] = right;
        adjacency_count[left] += 1;
        adjacency[right * MAX_N + adjacency_count[right]] = left;
        adjacency_count[right] += 1;
        degree[left] += 1;
        degree[right] += 1;
    }
    if n > 1 && component_size[find_root(&mut parent, 0)] != n {
        return -1;
    }

    let mut active = [false; MAX_N];
    let mut leaves = [0usize; MAX_N];
    let mut leaf_count = 0usize;
    for vertex in 0..n {
        active[vertex] = true;
        if degree[vertex] <= 1 {
            leaves[leaf_count] = vertex;
            leaf_count += 1;
        }
    }
    let mut remaining = n;
    while remaining > 2 {
        for index in 0..leaf_count {
            active[leaves[index]] = false;
        }
        remaining -= leaf_count;
        for index in 0..leaf_count {
            let leaf = leaves[index];
            for edge in 0..adjacency_count[leaf] {
                let neighbor = adjacency[leaf * MAX_N + edge];
                if active[neighbor] {
                    degree[neighbor] -= 1;
                }
            }
        }
        if remaining <= 2 {
            break;
        }
        leaf_count = 0;
        for vertex in 0..n {
            if active[vertex] && degree[vertex] == 1 {
                leaves[leaf_count] = vertex;
                leaf_count += 1;
            }
        }
    }

    let mut centers = [0i64; 2];
    let mut center_count = 0usize;
    for vertex in 0..n {
        if active[vertex] {
            centers[center_count] = vertex as i64;
            center_count += 1;
        }
    }
    let required = 8 * center_count;
    if output.is_null() || capacity < required {
        return -2;
    }
    for index in 0..center_count {
        store_i64_le(output, 8 * index, centers[index]);
    }
    required as i64
}
