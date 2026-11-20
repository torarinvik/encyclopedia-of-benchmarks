/// Lazy range addition and sum-monoid max_right boundary searches.
const TREE_LEN: usize = 64;

fn apply(tree: &mut [i64; TREE_LEN], lazy: &mut [i64; TREE_LEN],
         node: usize, segment_length: usize, delta: i64) {
    tree[node] += delta * segment_length as i64;
    lazy[node] += delta;
}

fn push(tree: &mut [i64; TREE_LEN], lazy: &mut [i64; TREE_LEN],
        node: usize, segment_length: usize) {
    if segment_length > 1 && lazy[node] != 0 {
        let half = segment_length / 2;
        let delta = lazy[node];
        apply(tree, lazy, 2 * node, half, delta);
        apply(tree, lazy, 2 * node + 1, half, delta);
        lazy[node] = 0;
    }
}

fn range_add(tree: &mut [i64; TREE_LEN], lazy: &mut [i64; TREE_LEN],
             node: usize, low: usize, high: usize, query_low: usize,
             query_high: usize, delta: i64) {
    if query_low >= query_high { return; }
    if query_high <= low || high <= query_low { return; }
    if query_low <= low && high <= query_high {
        apply(tree, lazy, node, high - low, delta);
        return;
    }
    push(tree, lazy, node, high - low);
    let middle = (low + high) / 2;
    if query_low < middle {
        range_add(tree, lazy, 2 * node, low, middle, query_low, query_high, delta);
    }
    if query_high > middle {
        range_add(tree, lazy, 2 * node + 1, middle, high, query_low, query_high, delta);
    }
    tree[node] = tree[2 * node] + tree[2 * node + 1];
}

fn max_right(tree: &mut [i64; TREE_LEN], lazy: &mut [i64; TREE_LEN],
             node: usize, low: usize, high: usize, n: usize, left: usize,
             limit: i64, accumulated: &mut i64) -> usize {
    if high <= left { return high; }
    if low >= n { return n; }
    if left <= low && high <= n && *accumulated + tree[node] <= limit {
        *accumulated += tree[node];
        return high;
    }
    if high - low == 1 { return low; }
    push(tree, lazy, node, high - low);
    let middle = (low + high) / 2;
    let first = max_right(tree, lazy, 2 * node, low, middle, n, left, limit, accumulated);
    if first < middle && first >= left { return first; }
    max_right(tree, lazy, 2 * node + 1, middle, high, n, left, limit, accumulated)
}

#[no_mangle]
pub extern "C" fn lazy_segment_tree_range_add_max_right(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(3..=67).contains(&length) { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if !(1..=16).contains(&input[0]) || !(0..=12).contains(&input[1]) { return -1; }
    let n = input[0] as usize;
    let operations = input[1] as usize;
    if length != 2 + n + 4 * operations { return -1; }
    if input[2..2 + n].iter().any(|&v| !(0..=31).contains(&v)) { return -1; }
    for operation in 0..operations {
        let p = 2 + n + 4 * operation;
        let (op, left, right, extra) = (input[p], input[p + 1], input[p + 2], input[p + 3]);
        if op == 0 {
            if left < 0 || left > n as i64 || right < left || right > n as i64
                || !(0..=31).contains(&extra) { return -1; }
        } else if op == 1 {
            if left < 0 || left > n as i64 || !(0..=8192).contains(&right) || extra != 0 { return -1; }
        } else { return -1; }
    }

    let mut size = 1usize;
    while size < n { size *= 2; }
    let mut tree = [0i64; TREE_LEN];
    let mut lazy = [0i64; TREE_LEN];
    for i in 0..n { tree[size + i] = input[2 + i]; }
    for node in (1..size).rev() { tree[node] = tree[2 * node] + tree[2 * node + 1]; }

    let mut query_index = 0usize;
    let mut result = 0i64;
    for operation in 0..operations {
        let p = 2 + n + 4 * operation;
        let left = input[p + 1] as usize;
        let right = input[p + 2] as usize;
        if input[p] == 0 {
            range_add(&mut tree, &mut lazy, 1, 0, size, left, right, input[p + 3]);
        } else {
            let mut accumulated = 0;
            let boundary = max_right(&mut tree, &mut lazy, 1, 0, size, n, left,
                                     right as i64, &mut accumulated);
            result |= (boundary as i64) << (5 * query_index);
            query_index += 1;
        }
    }
    result
}
