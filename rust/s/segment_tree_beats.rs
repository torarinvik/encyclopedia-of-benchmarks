const MAX_ITEMS: usize = 64;
const MAX_OPERATIONS: usize = 128;
const MAX_INPUT_VALUES: usize = 2 + MAX_ITEMS + 4 * MAX_OPERATIONS;
const TREE_SIZE: usize = 4 * MAX_ITEMS;
const VALUE_LIMIT: i64 = 1_000_000;
const INF: i64 = i64::MAX / 4;
const QUERY_OFFSET: i64 = 8_256_000_001;

#[derive(Clone, Copy)]
struct Node {
    sum: i64,
    max1: i64,
    max2: i64,
    min1: i64,
    min2: i64,
    add: i64,
    max_count: usize,
    min_count: usize,
}

impl Node {
    const EMPTY: Self = Self {
        sum: 0,
        max1: 0,
        max2: -INF,
        min1: 0,
        min2: INF,
        add: 0,
        max_count: 0,
        min_count: 0,
    };
}

fn pull(tree: &mut [Node; TREE_SIZE], node: usize) {
    let left = tree[2 * node];
    let right = tree[2 * node + 1];
    let current = &mut tree[node];
    current.sum = left.sum + right.sum;
    current.add = 0;
    if left.max1 == right.max1 {
        current.max1 = left.max1;
        current.max2 = left.max2.max(right.max2);
        current.max_count = left.max_count + right.max_count;
    } else if left.max1 > right.max1 {
        current.max1 = left.max1;
        current.max2 = left.max2.max(right.max1);
        current.max_count = left.max_count;
    } else {
        current.max1 = right.max1;
        current.max2 = left.max1.max(right.max2);
        current.max_count = right.max_count;
    }
    if left.min1 == right.min1 {
        current.min1 = left.min1;
        current.min2 = left.min2.min(right.min2);
        current.min_count = left.min_count + right.min_count;
    } else if left.min1 < right.min1 {
        current.min1 = left.min1;
        current.min2 = left.min2.min(right.min1);
        current.min_count = left.min_count;
    } else {
        current.min1 = right.min1;
        current.min2 = left.min1.min(right.min2);
        current.min_count = right.min_count;
    }
}

fn build(tree: &mut [Node; TREE_SIZE], values: &[i64], node: usize, low: usize, high: usize) {
    if high - low == 1 {
        let value = values[low];
        tree[node] = Node { sum: value, max1: value, max2: -INF, min1: value, min2: INF, add: 0, max_count: 1, min_count: 1 };
        return;
    }
    let middle = low + (high - low) / 2;
    build(tree, values, 2 * node, low, middle);
    build(tree, values, 2 * node + 1, middle, high);
    pull(tree, node);
}

fn apply_add(item: &mut Node, length: usize, delta: i64) {
    item.sum += delta * length as i64;
    item.max1 += delta;
    item.min1 += delta;
    if item.max2 != -INF { item.max2 += delta; }
    if item.min2 != INF { item.min2 += delta; }
    item.add += delta;
}

fn apply_chmin(item: &mut Node, ceiling: i64) {
    if item.max1 <= ceiling { return; }
    item.sum += (ceiling - item.max1) * item.max_count as i64;
    if item.min1 == item.max1 { item.min1 = ceiling; }
    else if item.min2 == item.max1 { item.min2 = ceiling; }
    item.max1 = ceiling;
}

fn apply_chmax(item: &mut Node, floor: i64) {
    if item.min1 >= floor { return; }
    item.sum += (floor - item.min1) * item.min_count as i64;
    if item.max1 == item.min1 { item.max1 = floor; }
    else if item.max2 == item.min1 { item.max2 = floor; }
    item.min1 = floor;
}

fn push(tree: &mut [Node; TREE_SIZE], node: usize, low: usize, high: usize) {
    if high - low == 1 { return; }
    let middle = low + (high - low) / 2;
    let delta = tree[node].add;
    if delta != 0 {
        apply_add(&mut tree[2 * node], middle - low, delta);
        apply_add(&mut tree[2 * node + 1], high - middle, delta);
        tree[node].add = 0;
    }
    let max1 = tree[node].max1;
    if tree[2 * node].max1 > max1 { apply_chmin(&mut tree[2 * node], max1); }
    if tree[2 * node + 1].max1 > max1 { apply_chmin(&mut tree[2 * node + 1], max1); }
    let min1 = tree[node].min1;
    if tree[2 * node].min1 < min1 { apply_chmax(&mut tree[2 * node], min1); }
    if tree[2 * node + 1].min1 < min1 { apply_chmax(&mut tree[2 * node + 1], min1); }
}

fn range_add(tree: &mut [Node; TREE_SIZE], node: usize, low: usize, high: usize,
             ql: usize, qr: usize, delta: i64) {
    if qr <= low || high <= ql || delta == 0 { return; }
    if ql <= low && high <= qr {
        apply_add(&mut tree[node], high - low, delta);
        return;
    }
    push(tree, node, low, high);
    let middle = low + (high - low) / 2;
    range_add(tree, 2 * node, low, middle, ql, qr, delta);
    range_add(tree, 2 * node + 1, middle, high, ql, qr, delta);
    pull(tree, node);
}

fn range_chmin(tree: &mut [Node; TREE_SIZE], node: usize, low: usize, high: usize,
               ql: usize, qr: usize, ceiling: i64) {
    if qr <= low || high <= ql || tree[node].max1 <= ceiling { return; }
    if ql <= low && high <= qr && tree[node].max2 < ceiling {
        apply_chmin(&mut tree[node], ceiling);
        return;
    }
    push(tree, node, low, high);
    let middle = low + (high - low) / 2;
    range_chmin(tree, 2 * node, low, middle, ql, qr, ceiling);
    range_chmin(tree, 2 * node + 1, middle, high, ql, qr, ceiling);
    pull(tree, node);
}

fn range_chmax(tree: &mut [Node; TREE_SIZE], node: usize, low: usize, high: usize,
               ql: usize, qr: usize, floor: i64) {
    if qr <= low || high <= ql || tree[node].min1 >= floor { return; }
    if ql <= low && high <= qr && tree[node].min2 > floor {
        apply_chmax(&mut tree[node], floor);
        return;
    }
    push(tree, node, low, high);
    let middle = low + (high - low) / 2;
    range_chmax(tree, 2 * node, low, middle, ql, qr, floor);
    range_chmax(tree, 2 * node + 1, middle, high, ql, qr, floor);
    pull(tree, node);
}

fn range_sum(tree: &mut [Node; TREE_SIZE], node: usize, low: usize, high: usize,
             ql: usize, qr: usize) -> i64 {
    if qr <= low || high <= ql { return 0; }
    if ql <= low && high <= qr { return tree[node].sum; }
    push(tree, node, low, high);
    let middle = low + (high - low) / 2;
    range_sum(tree, 2 * node, low, middle, ql, qr) +
        range_sum(tree, 2 * node + 1, middle, high, ql, qr)
}

#[no_mangle]
pub unsafe extern "C" fn segment_tree_beats(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT_VALUES { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values[0] < 1 || values[0] > MAX_ITEMS as i64 { return -1; }
    let n = values[0] as usize;
    if length < n + 2 || values[n + 1] < 0 || values[n + 1] > MAX_OPERATIONS as i64 { return -1; }
    let q = values[n + 1] as usize;
    if length != n + 2 + 4 * q { return -1; }
    if values[1..=n].iter().any(|&value| !(-VALUE_LIMIT..=VALUE_LIMIT).contains(&value)) { return -1; }
    for operation in 0..q {
        let p = n + 2 + 4 * operation;
        let (opcode, left, right, argument) = (values[p], values[p + 1], values[p + 2], values[p + 3]);
        if !(0..=3).contains(&opcode) || left < 0 || left >= right || right > n as i64 { return -1; }
        if (opcode == 3 && argument != 0) || (opcode != 3 && !(-VALUE_LIMIT..=VALUE_LIMIT).contains(&argument)) { return -1; }
    }

    let mut tree = [Node::EMPTY; TREE_SIZE];
    build(&mut tree, &values[1..=n], 1, 0, n);
    let (mut checksum, mut ordinal) = (0_i64, 0_i64);
    for operation in 0..q {
        let p = n + 2 + 4 * operation;
        let (left, right) = (values[p + 1] as usize, values[p + 2] as usize);
        let argument = values[p + 3];
        match values[p] {
            0 => range_chmin(&mut tree, 1, 0, n, left, right, argument),
            1 => range_chmax(&mut tree, 1, 0, n, left, right, argument),
            2 => range_add(&mut tree, 1, 0, n, left, right, argument),
            _ => {
                ordinal += 1;
                checksum += ordinal * (range_sum(&mut tree, 1, 0, n, left, right) + QUERY_OFFSET);
            }
        }
    }
    checksum
}
