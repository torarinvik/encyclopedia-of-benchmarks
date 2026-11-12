const MAX_N: usize = 64;
const MAX_INPUT_VALUES: usize = 1 + 3 * (MAX_N - 1);
const MAX_OUTPUT_VALUES: usize = 2 + MAX_N;

fn find_root(parent: &mut [usize; MAX_N], mut item: usize) -> usize {
    while parent[item] != item {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    item
}

fn traverse(
    n: usize,
    start: usize,
    adjacent: &[[bool; MAX_N]; MAX_N],
    weight: &[[i64; MAX_N]; MAX_N],
    distance: &mut [i64; MAX_N],
    parent: &mut [i64; MAX_N],
) {
    for vertex in 0..n {
        distance[vertex] = -1;
        parent[vertex] = -1;
    }
    let mut stack = [0usize; MAX_N];
    let mut top = 1usize;
    stack[0] = start;
    distance[start] = 0;
    while top > 0 {
        top -= 1;
        let vertex = stack[top];
        for neighbor in 0..n {
            if !adjacent[vertex][neighbor] || distance[neighbor] >= 0 {
                continue;
            }
            distance[neighbor] = distance[vertex] + weight[vertex][neighbor];
            parent[neighbor] = vertex as i64;
            stack[top] = neighbor;
            top += 1;
        }
    }
}

fn farthest(n: usize, distance: &[i64; MAX_N]) -> usize {
    let mut best = 0usize;
    for vertex in 1..n {
        if distance[vertex] > distance[best]
            || (distance[vertex] == distance[best] && vertex < best)
        {
            best = vertex;
        }
    }
    best
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn tree_diameter(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_VALUES {
        return -1;
    }
    let n_value = *input;
    if n_value < 1 || n_value > MAX_N as i64 {
        return -1;
    }
    let n = n_value as usize;
    if length != 1 + 3 * (n - 1) {
        return -1;
    }

    let mut adjacent = [[false; MAX_N]; MAX_N];
    let mut weight = [[0i64; MAX_N]; MAX_N];
    let mut dsu_parent = [0usize; MAX_N];
    let mut dsu_size = [0usize; MAX_N];
    for vertex in 0..n {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    for edge in 0..n - 1 {
        let offset = 1 + 3 * edge;
        let left_value = *input.add(offset);
        let right_value = *input.add(offset + 1);
        let edge_weight = *input.add(offset + 2);
        if left_value < 0
            || left_value >= n_value
            || right_value < 0
            || right_value >= n_value
            || left_value == right_value
            || !(1..=1_000_000_000).contains(&edge_weight)
        {
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
        weight[left][right] = edge_weight;
        weight[right][left] = edge_weight;
    }

    let mut distance = [0i64; MAX_N];
    let mut parent = [0i64; MAX_N];
    traverse(n, 0, &adjacent, &weight, &mut distance, &mut parent);
    let first_endpoint = farthest(n, &distance);
    traverse(n, first_endpoint, &adjacent, &weight, &mut distance, &mut parent);
    let second_endpoint = farthest(n, &distance);
    let mut reverse_path = [0usize; MAX_N];
    let mut path_length = 0usize;
    let mut current = second_endpoint as i64;
    while current >= 0 {
        reverse_path[path_length] = current as usize;
        path_length += 1;
        if current as usize == first_endpoint {
            break;
        }
        current = parent[current as usize];
    }

    let mut staged = [0i64; MAX_OUTPUT_VALUES];
    let mut used = 0usize;
    staged[used] = distance[second_endpoint];
    used += 1;
    staged[used] = path_length as i64;
    used += 1;
    for position in 0..path_length {
        staged[used] = reverse_path[path_length - 1 - position] as i64;
        used += 1;
    }
    let required = 8 * used;
    if output.is_null() || capacity < required {
        return -2;
    }
    for index in 0..used {
        store_i64_le(output, 8 * index, staged[index]);
    }
    required as i64
}
