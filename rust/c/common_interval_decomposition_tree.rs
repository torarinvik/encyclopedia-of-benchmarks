const MAX_N: usize = 48;
const MAX_NODES: usize = 2 * MAX_N - 1;
const GRID: usize = MAX_N * MAX_N;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let mut bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = bits as u8;
        bits >>= 8;
    }
}

fn intervals_overlap(left_a: usize, right_a: usize, left_b: usize, right_b: usize) -> bool {
    (left_a < left_b && left_b <= right_a && right_a < right_b)
        || (left_b < left_a && left_a <= right_b && right_b < right_a)
}

#[no_mangle]
pub unsafe extern "C" fn common_interval_decomposition_tree(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 1 + MAX_N {
        return -1;
    }
    let n_value = *input;
    if !(1..=MAX_N as i64).contains(&n_value) {
        return -1;
    }
    let n = n_value as usize;
    if length != n + 1 {
        return -1;
    }

    let mut seen = [false; MAX_N];
    for i in 0..n {
        let value = *input.add(i + 1);
        if value < 0 || value >= n as i64 || seen[value as usize] {
            return -1;
        }
        seen[value as usize] = true;
    }

    let mut connected = [false; GRID];
    let mut strong = [false; GRID];
    for left in 0..n {
        let mut minimum = n as i64;
        let mut maximum = -1i64;
        for right in left..n {
            let value = *input.add(right + 1);
            minimum = minimum.min(value);
            maximum = maximum.max(value);
            let slot = left * MAX_N + right;
            if maximum - minimum == (right - left) as i64 {
                connected[slot] = true;
                strong[slot] = true;
            }
        }
    }

    for left_a in 0..n {
        for right_a in left_a..n {
            let slot_a = left_a * MAX_N + right_a;
            if !connected[slot_a] {
                continue;
            }
            for left_b in 0..n {
                for right_b in left_b..n {
                    let slot_b = left_b * MAX_N + right_b;
                    if slot_b <= slot_a || !connected[slot_b] {
                        continue;
                    }
                    if intervals_overlap(left_a, right_a, left_b, right_b) {
                        strong[slot_a] = false;
                        strong[slot_b] = false;
                    }
                }
            }
        }
    }

    let mut node_left = [0i64; MAX_NODES];
    let mut node_right = [0i64; MAX_NODES];
    let mut parent = [-1i64; MAX_NODES];
    let mut node_type = [0i64; MAX_NODES];
    let mut node_count = 0usize;
    for span in (1..=n).rev() {
        for left in 0..=n - span {
            let right = left + span - 1;
            if !strong[left * MAX_N + right] {
                continue;
            }
            node_left[node_count] = left as i64;
            node_right[node_count] = right as i64;
            node_count += 1;
        }
    }
    if node_count == 0 || node_count > MAX_NODES {
        return -1;
    }

    for node in 0..node_count {
        let span = node_right[node] - node_left[node] + 1;
        let mut best_span = n as i64 + 1;
        for candidate in 0..node_count {
            let candidate_span = node_right[candidate] - node_left[candidate] + 1;
            if candidate_span > span
                && candidate_span < best_span
                && node_left[candidate] <= node_left[node]
                && node_right[node] <= node_right[candidate]
            {
                parent[node] = candidate as i64;
                best_span = candidate_span;
            }
        }
    }

    for node in 0..node_count {
        let mut children = [0usize; MAX_N];
        let mut child_count = 0usize;
        for child in 0..node_count {
            if parent[child] != node as i64 {
                continue;
            }
            let mut at = child_count;
            while at > 0 && node_left[children[at - 1]] > node_left[child] {
                children[at] = children[at - 1];
                at -= 1;
            }
            children[at] = child;
            child_count += 1;
        }

        for first in 0..child_count {
            for last in first..child_count {
                let left = node_left[children[first]] as usize;
                let right = node_right[children[last]] as usize;
                let mut minimum = n as i64;
                let mut maximum = -1i64;
                for position in left..=right {
                    let value = *input.add(position + 1);
                    minimum = minimum.min(value);
                    maximum = maximum.max(value);
                }
                if maximum - minimum != (right - left) as i64 {
                    node_type[node] = 1;
                    break;
                }
            }
            if node_type[node] != 0 {
                break;
            }
        }
    }

    let output_bytes = (1 + 4 * node_count) * 8;
    if output.is_null() || capacity < output_bytes {
        return -2;
    }
    store_i64_le(output, 0, node_count as i64);
    for node in 0..node_count {
        let offset = 8 + 32 * node;
        store_i64_le(output, offset, parent[node]);
        store_i64_le(output, offset + 8, node_left[node]);
        store_i64_le(output, offset + 16, node_right[node]);
        store_i64_le(output, offset + 24, node_type[node]);
    }
    output_bytes as i64
}
