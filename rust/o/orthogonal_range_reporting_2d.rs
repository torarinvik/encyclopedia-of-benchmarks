const MAX_POINTS: usize = 8;
const MAX_QUERIES: usize = 8;
const MAX_INPUT_LENGTH: usize = 50;
const BASE: usize = 8;
const MAX_OUTPUT_WORDS: usize = 73;

fn lower_x(order: &[usize; MAX_POINTS], n: usize, xs: &[i64; MAX_POINTS], bound: i64) -> usize {
    let (mut low, mut high) = (0, n);
    while low < high {
        let middle = low + (high - low) / 2;
        if xs[order[middle]] < bound { low = middle + 1; } else { high = middle; }
    }
    low
}

fn upper_x(order: &[usize; MAX_POINTS], n: usize, xs: &[i64; MAX_POINTS], bound: i64) -> usize {
    let (mut low, mut high) = (0, n);
    while low < high {
        let middle = low + (high - low) / 2;
        if xs[order[middle]] <= bound { low = middle + 1; } else { high = middle; }
    }
    low
}

fn report_node(node: usize, tree_ids: &[[usize; MAX_POINTS]; 2 * BASE],
    tree_size: &[usize; 2 * BASE], ys: &[i64; MAX_POINTS], y_low: i64,
    y_high: i64, hits: &mut [usize; MAX_POINTS], offset: usize) -> usize {
    let (mut low, mut high) = (0, tree_size[node]);
    while low < high {
        let middle = low + (high - low) / 2;
        if ys[tree_ids[node][middle]] < y_low { low = middle + 1; } else { high = middle; }
    }
    let first = low;
    high = tree_size[node];
    while low < high {
        let middle = low + (high - low) / 2;
        if ys[tree_ids[node][middle]] <= y_high { low = middle + 1; } else { high = middle; }
    }
    for index in first..low { hits[offset + index - first] = tree_ids[node][index]; }
    low - first
}

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    unsafe { std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(offset), 8); }
}

#[no_mangle]
pub unsafe extern "C" fn orthogonal_range_reporting_2d(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let n_value = *input;
    let q_value = *input.add(1);
    if n_value < 1 || n_value > MAX_POINTS as i64 || q_value < 1 || q_value > MAX_QUERIES as i64 { return -1; }
    let n = n_value as usize;
    let q = q_value as usize;
    if length != 2 + 2 * n + 4 * q { return -1; }

    let mut xs = [0i64; MAX_POINTS];
    let mut ys = [0i64; MAX_POINTS];
    for point in 0..n {
        xs[point] = *input.add(2 + 2 * point);
        ys[point] = *input.add(3 + 2 * point);
        if !(0..=15).contains(&xs[point]) || !(0..=15).contains(&ys[point]) { return -1; }
        for earlier in 0..point {
            if xs[earlier] == xs[point] && ys[earlier] == ys[point] { return -1; }
        }
    }
    let mut queries = [[0i64; 4]; MAX_QUERIES];
    let start = 2 + 2 * n;
    for query in 0..q {
        for item in 0..4 { queries[query][item] = *input.add(start + 4 * query + item); }
        if queries[query][0] < 0 || queries[query][0] > queries[query][1] || queries[query][1] > 15 ||
            queries[query][2] < 0 || queries[query][2] > queries[query][3] || queries[query][3] > 15 { return -1; }
    }

    let mut order = [0usize; MAX_POINTS];
    for point in 0..n { order[point] = point; }
    for index in 1..n {
        let item = order[index];
        let mut position = index;
        while position > 0 && (xs[item], ys[item], item) < (xs[order[position - 1]], ys[order[position - 1]], order[position - 1]) {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = item;
    }

    let mut tree_ids = [[0usize; MAX_POINTS]; 2 * BASE];
    let mut tree_size = [0usize; 2 * BASE];
    for rank in 0..n {
        tree_ids[BASE + rank][0] = order[rank];
        tree_size[BASE + rank] = 1;
    }
    for node in (1..BASE).rev() {
        let (mut left, mut right) = (0, 0);
        let (left_node, right_node) = (node * 2, node * 2 + 1);
        while left < tree_size[left_node] || right < tree_size[right_node] {
            let take_left = right >= tree_size[right_node] ||
                left < tree_size[left_node] &&
                (ys[tree_ids[left_node][left]], tree_ids[left_node][left]) <
                (ys[tree_ids[right_node][right]], tree_ids[right_node][right]);
            let chosen = if take_left {
                let value = tree_ids[left_node][left];
                left += 1;
                value
            } else {
                let value = tree_ids[right_node][right];
                right += 1;
                value
            };
            tree_ids[node][tree_size[node]] = chosen;
            tree_size[node] += 1;
        }
    }

    let mut words = [0i64; MAX_OUTPUT_WORDS];
    let mut cursor = 0usize;
    words[cursor] = q as i64;
    cursor += 1;
    for query in 0..q {
        let mut left = lower_x(&order, n, &xs, queries[query][0]) + BASE;
        let mut right = upper_x(&order, n, &xs, queries[query][1]) + BASE;
        let mut hits = [0usize; MAX_POINTS];
        let mut hit_count = 0usize;
        while left < right {
            if left & 1 != 0 {
                hit_count += report_node(left, &tree_ids, &tree_size, &ys,
                    queries[query][2], queries[query][3], &mut hits, hit_count);
                left += 1;
            }
            if right & 1 != 0 {
                right -= 1;
                hit_count += report_node(right, &tree_ids, &tree_size, &ys,
                    queries[query][2], queries[query][3], &mut hits, hit_count);
            }
            left /= 2;
            right /= 2;
        }
        for index in 1..hit_count {
            let item = hits[index];
            let mut position = index;
            while position > 0 && hits[position - 1] > item {
                hits[position] = hits[position - 1];
                position -= 1;
            }
            hits[position] = item;
        }
        words[cursor] = hit_count as i64;
        cursor += 1;
        for id in hits.iter().take(hit_count) {
            words[cursor] = *id as i64;
            cursor += 1;
        }
    }
    let output_bytes = 8 * cursor;
    if output.is_null() || capacity < output_bytes { return -2; }
    for index in 0..cursor { store_i64_le(output, index * 8, words[index]); }
    output_bytes as i64
}
