/// Historical maximum segment tree with ordered lazy add/assign summaries.
const MAX_N: usize = 32;
const MAX_Q: usize = 32;
const TREE_SIZE: usize = 4 * MAX_N;
const VALUE_LIMIT: i64 = 1000;

#[derive(Clone, Copy, Default)]
struct Node {
    maximum: i64,
    history_maximum: i64,
    add: i64,
    add_peak: i64,
    set_value: i64,
    set_peak: i64,
    has_set: bool,
}

fn apply_add_summary(node: &mut Node, net: i64, peak: i64) {
    node.history_maximum = node.history_maximum.max(node.maximum + peak);
    node.maximum += net;
    if node.has_set {
        node.set_peak = node.set_peak.max(node.set_value + peak);
        node.set_value += net;
    } else {
        node.add_peak = node.add_peak.max(node.add + peak);
        node.add += net;
    }
}

fn apply_add(node: &mut Node, delta: i64) {
    if node.has_set {
        node.set_peak = node.set_peak.max(node.set_value + delta);
        node.set_value += delta;
    } else {
        node.add_peak = node.add_peak.max(node.add + delta);
        node.add += delta;
    }
    node.history_maximum = node.history_maximum.max(node.maximum + delta);
    node.maximum += delta;
}

fn apply_set_summary(node: &mut Node, value: i64, peak: i64) {
    node.history_maximum = node.history_maximum.max(peak);
    node.maximum = value;
    if node.has_set { node.set_peak = node.set_peak.max(peak); }
    else { node.has_set = true; node.set_peak = peak; }
    node.set_value = value;
}

fn apply_set(node: &mut Node, value: i64) {
    node.history_maximum = node.history_maximum.max(value);
    node.maximum = value;
    if node.has_set { node.set_peak = node.set_peak.max(value); }
    else { node.has_set = true; node.set_peak = value; }
    node.set_value = value;
}

fn push(tree: &mut [Node; TREE_SIZE], node: usize) {
    let parent = tree[node];
    if parent.add != 0 || parent.add_peak != 0 {
        apply_add_summary(&mut tree[2 * node], parent.add, parent.add_peak);
        apply_add_summary(&mut tree[2 * node + 1], parent.add, parent.add_peak);
        tree[node].add = 0;
        tree[node].add_peak = 0;
    }
    if parent.has_set {
        apply_set_summary(&mut tree[2 * node], parent.set_value, parent.set_peak);
        apply_set_summary(&mut tree[2 * node + 1], parent.set_value, parent.set_peak);
        tree[node].has_set = false;
        tree[node].set_value = 0;
        tree[node].set_peak = 0;
    }
}

fn pull(tree: &mut [Node; TREE_SIZE], node: usize) {
    tree[node].maximum = tree[2 * node].maximum.max(tree[2 * node + 1].maximum);
    tree[node].history_maximum = tree[2 * node].history_maximum.max(tree[2 * node + 1].history_maximum);
}

fn build(tree: &mut [Node; TREE_SIZE], values: &[i64], node: usize, left: usize, right: usize) {
    if right - left == 1 {
        tree[node].maximum = values[left];
        tree[node].history_maximum = values[left];
        return;
    }
    let middle = left + (right - left) / 2;
    build(tree, values, 2 * node, left, middle);
    build(tree, values, 2 * node + 1, middle, right);
    pull(tree, node);
}

fn update(tree: &mut [Node; TREE_SIZE], node: usize, left: usize, right: usize,
          ql: usize, qr: usize, assignment: bool, value: i64) {
    if ql <= left && right <= qr {
        if assignment { apply_set(&mut tree[node], value); } else { apply_add(&mut tree[node], value); }
        return;
    }
    push(tree, node);
    let middle = left + (right - left) / 2;
    if ql < middle { update(tree, 2 * node, left, middle, ql, qr, assignment, value); }
    if middle < qr { update(tree, 2 * node + 1, middle, right, ql, qr, assignment, value); }
    pull(tree, node);
}

fn query(tree: &mut [Node; TREE_SIZE], node: usize, left: usize, right: usize,
         ql: usize, qr: usize, history: bool) -> i64 {
    if ql <= left && right <= qr {
        return if history { tree[node].history_maximum } else { tree[node].maximum };
    }
    push(tree, node);
    let middle = left + (right - left) / 2;
    let mut answer = i64::MIN;
    if ql < middle { answer = query(tree, 2 * node, left, middle, ql, qr, history); }
    if middle < qr { answer = answer.max(query(tree, 2 * node + 1, middle, right, ql, qr, history)); }
    answer
}

#[no_mangle]
pub unsafe extern "C" fn segment_history_extreme(
    input: *const i64, input_length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 2 || input_length > 2 + MAX_N + 4 * MAX_Q { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let n_value = values[0];
    let q_value = values[1];
    if !(1..=MAX_N as i64).contains(&n_value) || !(0..=MAX_Q as i64).contains(&q_value) { return -1; }
    let n = n_value as usize;
    let q = q_value as usize;
    if input_length != 2 + n + 4 * q { return -1; }
    let operation_offset = 2 + n;
    let initial = &values[2..2 + n];
    if initial.iter().any(|&value| !(-VALUE_LIMIT..=VALUE_LIMIT).contains(&value)) { return -1; }
    for i in 0..q {
        let record = &values[operation_offset + 4 * i..operation_offset + 4 * i + 4];
        let (op, left, right, arg) = (record[0], record[1], record[2], record[3]);
        if !(0..=3).contains(&op) || left < 0 || right <= left || right > n_value { return -1; }
        if (op < 2 && !(-VALUE_LIMIT..=VALUE_LIMIT).contains(&arg)) || (op >= 2 && arg != 0) { return -1; }
    }

    let mut tree = [Node::default(); TREE_SIZE];
    let mut staged = [0_i64; MAX_Q];
    let mut answer_count = 0_usize;
    build(&mut tree, initial, 1, 0, n);
    for i in 0..q {
        let record = &values[operation_offset + 4 * i..operation_offset + 4 * i + 4];
        let op = record[0] as usize;
        let left = record[1] as usize;
        let right = record[2] as usize;
        if op < 2 {
            update(&mut tree, 1, 0, n, left, right, op == 0, record[3]);
        } else {
            staged[answer_count] = query(&mut tree, 1, 0, n, left, right, op == 3);
            answer_count += 1;
        }
    }
    let output_bytes = 8 * answer_count;
    if output.is_null() || output_capacity < output_bytes { return -2; }
    for i in 0..answer_count {
        let bits = staged[i] as u64;
        for byte in 0..8 { *output.add(8 * i + byte) = (bits >> (8 * byte)) as u8; }
    }
    output_bytes as i64
}
