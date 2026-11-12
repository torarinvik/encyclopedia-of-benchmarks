const MAX_N: usize = 64;
const MAX_INPUT_VALUES: usize = 1 + 2 * (MAX_N - 1);

#[derive(Clone, Copy)]
struct WalkItem {
    vertex: usize,
    parent: usize,
    depth: usize,
}

fn find_root(parent: &mut [usize; MAX_N], mut item: usize) -> usize {
    while parent[item] != item {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    item
}

fn solve_component(
    n: usize,
    adjacent: &[[bool; MAX_N]; MAX_N],
    removed: &mut [bool; MAX_N],
    answer: &mut [i64; MAX_N],
    start: usize,
) {
    let mut order = [0usize; MAX_N];
    let mut parent = [0usize; MAX_N];
    let mut subtree = [0usize; MAX_N];
    let mut stack = [0usize; MAX_N];
    let mut order_count = 0usize;
    let mut top = 0usize;
    stack[top] = start;
    top += 1;
    parent[start] = start;
    subtree[start] = 1;
    order[order_count] = start;
    order_count += 1;
    while top > 0 {
        top -= 1;
        let vertex = stack[top];
        for neighbor in 0..n {
            if !adjacent[vertex][neighbor] || removed[neighbor] || neighbor == parent[vertex] {
                continue;
            }
            parent[neighbor] = vertex;
            subtree[neighbor] = 1;
            order[order_count] = neighbor;
            order_count += 1;
            stack[top] = neighbor;
            top += 1;
        }
    }
    for position in (1..order_count).rev() {
        let vertex = order[position];
        subtree[parent[vertex]] += subtree[vertex];
    }

    let mut centroid = MAX_N;
    for position in 0..order_count {
        let vertex = order[position];
        let mut largest_part = order_count - subtree[vertex];
        for neighbor in 0..n {
            if adjacent[vertex][neighbor]
                && !removed[neighbor]
                && parent[neighbor] == vertex
                && subtree[neighbor] > largest_part
            {
                largest_part = subtree[neighbor];
            }
        }
        if 2 * largest_part <= order_count && (centroid == MAX_N || vertex < centroid) {
            centroid = vertex;
        }
    }

    let mut frequency = [0i64; MAX_N];
    let mut frequency_max = 0usize;
    frequency[0] = 1;
    removed[centroid] = true;
    for child in 0..n {
        if !adjacent[centroid][child] || removed[child] {
            continue;
        }
        let mut local_frequency = [0usize; MAX_N];
        let mut walk = [WalkItem { vertex: 0, parent: 0, depth: 0 }; MAX_N];
        let mut local_max = 0usize;
        let mut walk_top = 0usize;
        walk[walk_top] = WalkItem { vertex: child, parent: centroid, depth: 1 };
        walk_top += 1;
        while walk_top > 0 {
            walk_top -= 1;
            let item = walk[walk_top];
            local_frequency[item.depth] += 1;
            local_max = local_max.max(item.depth);
            for neighbor in 0..n {
                if adjacent[item.vertex][neighbor] && !removed[neighbor] && neighbor != item.parent {
                    walk[walk_top] = WalkItem { vertex: neighbor, parent: item.vertex, depth: item.depth + 1 };
                    walk_top += 1;
                }
            }
        }
        for depth in 1..=local_max {
            for other in 0..=frequency_max {
                if depth + other < n {
                    answer[depth + other] += local_frequency[depth] as i64 * frequency[other];
                }
            }
        }
        for depth in 1..=local_max {
            frequency[depth] += local_frequency[depth] as i64;
        }
        frequency_max = frequency_max.max(local_max);
    }

    for child in 0..n {
        if adjacent[centroid][child] && !removed[child] {
            solve_component(n, adjacent, removed, answer, child);
        }
    }
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn frequency_table_of_tree_distance(
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
    if length != 1 + 2 * (n - 1) {
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
        let offset = 1 + 2 * edge;
        let left_value = *input.add(offset);
        let right_value = *input.add(offset + 1);
        if left_value < 0 || left_value >= n_value || right_value < 0 ||
            right_value >= n_value || left_value == right_value
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
    }

    let mut removed = [false; MAX_N];
    let mut answer = [0i64; MAX_N];
    solve_component(n, &adjacent, &mut removed, &mut answer, 0);
    let required = 8 * (n - 1);
    if output.is_null() || capacity < required {
        return -2;
    }
    for distance in 1..n {
        store_i64_le(output, 8 * (distance - 1), answer[distance]);
    }
    required as i64
}
