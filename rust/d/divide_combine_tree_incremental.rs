const MAX_N: usize = 16;
const MAX_NODES: usize = 2 * MAX_N - 1;
const TREE_SIZE: usize = 4 * MAX_N + 4;

fn add_range(
    node: usize, left: usize, right: usize, ql: usize, qr: usize, delta: i32,
    minimum: &mut [i32; TREE_SIZE], lazy: &mut [i32; TREE_SIZE],
) {
    if ql <= left && right <= qr {
        minimum[node] += delta;
        lazy[node] += delta;
        return;
    }
    let middle = (left + right) / 2;
    if lazy[node] != 0 {
        let tag = lazy[node];
        minimum[node * 2] += tag;
        minimum[node * 2 + 1] += tag;
        lazy[node * 2] += tag;
        lazy[node * 2 + 1] += tag;
        lazy[node] = 0;
    }
    if ql <= middle && qr >= left {
        add_range(node * 2, left, middle, ql, qr, delta, minimum, lazy);
    }
    if qr > middle && ql <= right {
        add_range(node * 2 + 1, middle + 1, right, ql, qr, delta, minimum, lazy);
    }
    minimum[node] = minimum[node * 2].min(minimum[node * 2 + 1]);
}

fn first_zero(node: usize, left: usize, right: usize, minimum: &[i32; TREE_SIZE]) -> usize {
    if left == right {
        return left;
    }
    let middle = (left + right) / 2;
    if minimum[node * 2] == 0 {
        first_zero(node * 2, left, middle, minimum)
    } else {
        first_zero(node * 2 + 1, middle + 1, right, minimum)
    }
}

fn connected(
    left: usize, right: usize, logs: &[usize; MAX_N + 1],
    range_min: &[[i32; MAX_N]; MAX_N], range_max: &[[i32; MAX_N]; MAX_N],
) -> bool {
    let level = logs[right - left + 1];
    let other = right + 1 - (1 << level);
    let low = range_min[level][left].min(range_min[level][other]);
    let high = range_max[level][left].max(range_max[level][other]);
    high - low == (right - left) as i32
}

fn new_node(
    left: i32, right: i32, combine: bool, last_left: i32, count: &mut usize,
    node_left: &mut [i32; MAX_NODES], node_right: &mut [i32; MAX_NODES],
    node_combine: &mut [bool; MAX_NODES], node_last: &mut [i32; MAX_NODES],
) -> usize {
    let id = *count;
    *count += 1;
    node_left[id] = left;
    node_right[id] = right;
    node_combine[id] = combine;
    node_last[id] = last_left;
    id
}

#[no_mangle]
pub unsafe extern "C" fn divide_combine_tree_incremental(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_N + 2 {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n_value = values[0];
    if n_value < 1 || n_value > MAX_N as i64 || length != n_value as usize + 1 {
        return -1;
    }
    let n = n_value as usize;
    let mut permutation = [0i32; MAX_N];
    let mut seen = [false; MAX_N];
    for i in 0..n {
        let value = values[i + 1];
        if value < 0 || value >= n as i64 || seen[value as usize] {
            return -1;
        }
        permutation[i] = value as i32;
        seen[value as usize] = true;
    }

    let mut logs = [0usize; MAX_N + 1];
    for i in 2..=n {
        logs[i] = logs[i / 2] + 1;
    }
    let levels = logs[n] + 1;
    let mut range_min = [[0i32; MAX_N]; MAX_N];
    let mut range_max = [[0i32; MAX_N]; MAX_N];
    for i in 0..n {
        range_min[0][i] = permutation[i];
        range_max[0][i] = permutation[i];
    }
    for level in 1..levels {
        let half = 1usize << (level - 1);
        let width = half * 2;
        for start in 0..=n - width {
            range_min[level][start] = range_min[level - 1][start]
                .min(range_min[level - 1][start + half]);
            range_max[level][start] = range_max[level - 1][start]
                .max(range_max[level - 1][start + half]);
        }
    }

    let mut segment_min = [0i32; TREE_SIZE];
    let mut lazy = [0i32; TREE_SIZE];
    let mut node_left = [0i32; MAX_NODES];
    let mut node_right = [0i32; MAX_NODES];
    let mut node_combine = [false; MAX_NODES];
    let mut node_last = [0i32; MAX_NODES];
    let mut node_stack = [0usize; MAX_N];
    let mut min_stack = [0usize; MAX_N];
    let mut max_stack = [0usize; MAX_N];
    let (mut node_top, mut min_top, mut max_top, mut node_count) = (0usize, 0usize, 0usize, 0usize);

    for end in 0..n {
        let value = permutation[end];
        while min_top > 0 && permutation[min_stack[min_top - 1]] >= value {
            min_top -= 1;
            let position = min_stack[min_top];
            let start = if min_top > 0 { min_stack[min_top - 1] + 1 } else { 0 };
            add_range(1, 0, n - 1, start, position, permutation[position], &mut segment_min, &mut lazy);
        }
        while max_top > 0 && permutation[max_stack[max_top - 1]] <= value {
            max_top -= 1;
            let position = max_stack[max_top];
            let start = if max_top > 0 { max_stack[max_top - 1] + 1 } else { 0 };
            add_range(1, 0, n - 1, start, position, -permutation[position], &mut segment_min, &mut lazy);
        }
        let start = if min_top > 0 { min_stack[min_top - 1] + 1 } else { 0 };
        add_range(1, 0, n - 1, start, end, -value, &mut segment_min, &mut lazy);
        min_stack[min_top] = end;
        min_top += 1;
        let start = if max_top > 0 { max_stack[max_top - 1] + 1 } else { 0 };
        add_range(1, 0, n - 1, start, end, value, &mut segment_min, &mut lazy);
        max_stack[max_top] = end;
        max_top += 1;

        let leftmost = first_zero(1, 0, n - 1, &segment_min);
        let mut current = new_node(end as i32, end as i32, false, 0, &mut node_count,
            &mut node_left, &mut node_right, &mut node_combine, &mut node_last);
        while node_top > 0 && node_left[node_stack[node_top - 1]] as usize >= leftmost {
            let top = node_stack[node_top - 1];
            if node_combine[top] && connected(node_last[top] as usize, end, &logs, &range_min, &range_max) {
                node_right[top] = end as i32;
                node_last[top] = node_left[current];
                node_top -= 1;
                current = node_stack[node_top];
            } else if connected(node_left[top] as usize, end, &logs, &range_min, &range_max) {
                let merged = new_node(node_left[top], end as i32, true, node_left[current], &mut node_count,
                    &mut node_left, &mut node_right, &mut node_combine, &mut node_last);
                node_top -= 1;
                current = merged;
            } else {
                let merged = new_node(-1, end as i32, false, 0, &mut node_count,
                    &mut node_left, &mut node_right, &mut node_combine, &mut node_last);
                loop {
                    node_top -= 1;
                    if node_top == 0 || connected(node_left[node_stack[node_top - 1]] as usize,
                                                  end, &logs, &range_min, &range_max) {
                        break;
                    }
                }
                if node_top == 0 {
                    return -1;
                }
                node_top -= 1;
                let base = node_stack[node_top];
                node_left[merged] = node_left[base];
                current = merged;
            }
        }
        node_stack[node_top] = current;
        node_top += 1;
        add_range(1, 0, n - 1, 0, end, -1, &mut segment_min, &mut lazy);
    }

    for i in 1..node_count {
        let left = node_left[i];
        let right = node_right[i];
        let mut j = i;
        while j > 0 && (node_left[j - 1] > left
            || (node_left[j - 1] == left && node_right[j - 1] > right)) {
            node_left[j] = node_left[j - 1];
            node_right[j] = node_right[j - 1];
            j -= 1;
        }
        node_left[j] = left;
        node_right[j] = right;
    }
    let mut checksum = 0i64;
    for i in 0..node_count {
        checksum += (i as i64 + 1)
            * ((node_left[i] as i64 + 1) * (n as i64 + 1) + node_right[i] as i64 + 1);
    }
    checksum
}
