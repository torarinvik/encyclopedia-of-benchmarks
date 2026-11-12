use std::slice;

const N: usize = 8;
const M: usize = 32;
const BASE: usize = 8;
const INPUT_MAX: usize = 2 + 2 * N + 4 * M;
const INF: i64 = 1 << 60;

#[derive(Clone, Copy, Default)]
struct Node { valid: bool, winner: usize, best: i64, lazy: i64, deadline: i64 }
#[derive(Clone, Copy, Default)]
struct Op { kind: i64, left: i64, right: i64, delta: i64 }

fn pull(tree: &mut [Node; 2 * BASE], node: usize, slope: &[i64; N]) {
    let (left, right) = (2 * node, 2 * node + 1);
    if !tree[left].valid && !tree[right].valid {
        tree[node].valid = false;
        tree[node].deadline = INF;
        return;
    }
    if !tree[left].valid || !tree[right].valid {
        let child = if tree[right].valid { right } else { left };
        tree[node].valid = true;
        tree[node].winner = tree[child].winner;
        tree[node].best = tree[child].best;
        tree[node].deadline = tree[child].deadline;
        return;
    }
    let (li, ri) = (tree[left].winner, tree[right].winner);
    let choose_left = tree[left].best > tree[right].best
        || (tree[left].best == tree[right].best && slope[li] > slope[ri]);
    let (win, lose) = if choose_left { (left, right) } else { (right, left) };
    let (wi, lo) = (tree[win].winner, tree[lose].winner);
    let mut crossing = INF;
    if slope[wi] < slope[lo] {
        let gap = tree[win].best - tree[lose].best;
        let slope_gap = slope[lo] - slope[wi];
        crossing = if gap <= 0 { 0 } else { (gap + slope_gap - 1) / slope_gap };
    }
    tree[node].valid = true;
    tree[node].winner = wi;
    tree[node].best = tree[win].best;
    tree[node].deadline = crossing.min(tree[left].deadline.min(tree[right].deadline));
}

fn apply(tree: &mut [Node; 2 * BASE], node: usize, slope: &[i64; N], delta: i64) {
    if !tree[node].valid { return; }
    tree[node].best += slope[tree[node].winner] * delta;
    tree[node].lazy += delta;
    tree[node].deadline -= delta;
}

fn push(tree: &mut [Node; 2 * BASE], node: usize, slope: &[i64; N]) {
    let delta = tree[node].lazy;
    if delta == 0 || node >= BASE { return; }
    apply(tree, 2 * node, slope, delta);
    apply(tree, 2 * node + 1, slope, delta);
    tree[node].lazy = 0;
}

fn repair(tree: &mut [Node; 2 * BASE], node: usize, slope: &[i64; N]) {
    if node >= BASE || !tree[node].valid { return; }
    push(tree, node, slope);
    if tree[2 * node].valid && tree[2 * node].deadline <= 0 {
        repair(tree, 2 * node, slope);
    }
    if tree[2 * node + 1].valid && tree[2 * node + 1].deadline <= 0 {
        repair(tree, 2 * node + 1, slope);
    }
    pull(tree, node, slope);
}

fn translate(tree: &mut [Node; 2 * BASE], node: usize, lo: usize, hi: usize,
    ql: usize, qr: usize, delta: i64, slope: &[i64; N]) {
    if ql <= lo && hi <= qr {
        apply(tree, node, slope, delta);
        repair(tree, node, slope);
        return;
    }
    push(tree, node, slope);
    let mid = (lo + hi) / 2;
    if ql < mid { translate(tree, 2 * node, lo, mid, ql, qr, delta, slope); }
    if mid < qr { translate(tree, 2 * node + 1, mid, hi, ql, qr, delta, slope); }
    pull(tree, node, slope);
}

fn query(tree: &mut [Node; 2 * BASE], node: usize, lo: usize, hi: usize,
    ql: usize, qr: usize, slope: &[i64; N]) -> i64 {
    if ql <= lo && hi <= qr { return tree[node].best; }
    push(tree, node, slope);
    let mid = (lo + hi) / 2;
    let mut answer = i64::MIN;
    if ql < mid { answer = query(tree, 2 * node, lo, mid, ql, qr, slope); }
    if mid < qr { answer = answer.max(query(tree, 2 * node + 1, mid, hi, ql, qr, slope)); }
    pull(tree, node, slope);
    answer
}

fn store(output: *mut u8, at: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { unsafe { output.add(at + byte).write((bits >> (8 * byte)) as u8); } }
}

#[no_mangle]
pub unsafe extern "C" fn kinetic_tournament_tree(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > INPUT_MAX { return -1; }
    let words = slice::from_raw_parts(input, length);
    let (nr, mr) = (words[0], words[1]);
    if nr < 1 || nr > N as i64 || mr < 1 || mr > M as i64 { return -1; }
    let (n, m) = (nr as usize, mr as usize);
    let mut cursor = 2;
    let mut slope = [0i64; N];
    let mut intercept = [0i64; N];
    for i in 0..n {
        if cursor + 2 > length { return -1; }
        slope[i] = words[cursor];
        intercept[i] = words[cursor + 1];
        cursor += 2;
        if !(-8..=8).contains(&slope[i]) || !(-64..=64).contains(&intercept[i])
            || (i > 0 && slope[i] <= slope[i - 1]) { return -1; }
    }
    let mut operations = [Op::default(); M];
    let mut query_count = 0usize;
    for op in operations.iter_mut().take(m) {
        if cursor >= length { return -1; }
        let kind = words[cursor];
        cursor += 1;
        if kind == 0 {
            if cursor + 3 > length { return -1; }
            let (left, right, delta) = (words[cursor], words[cursor + 1], words[cursor + 2]);
            cursor += 3;
            if left < 0 || left > right || right >= nr || !(1..=8).contains(&delta) { return -1; }
            *op = Op { kind, left, right, delta };
        } else if kind == 1 {
            if cursor + 2 > length { return -1; }
            let (left, right) = (words[cursor], words[cursor + 1]);
            cursor += 2;
            if left < 0 || left > right || right >= nr { return -1; }
            *op = Op { kind, left, right, delta: 0 };
            query_count += 1;
        } else { return -1; }
    }
    if cursor != length || query_count == 0 { return -1; }
    let required = 8 * query_count;
    if output.is_null() || capacity < required { return -2; }

    let mut tree = [Node::default(); 2 * BASE];
    for node in tree.iter_mut() { node.deadline = INF; }
    for i in 0..n {
        let node = BASE + i;
        tree[node].valid = true;
        tree[node].winner = i;
        tree[node].best = intercept[i];
    }
    for node in (1..BASE).rev() { pull(&mut tree, node, &slope); }
    let mut answers = [0i64; M];
    let mut answer_count = 0usize;
    for op in operations.iter().take(m).copied() {
        if op.kind == 0 {
            translate(&mut tree, 1, 0, BASE, op.left as usize, op.right as usize + 1, op.delta, &slope);
        } else {
            answers[answer_count] = query(&mut tree, 1, 0, BASE,
                op.left as usize, op.right as usize + 1, &slope);
            answer_count += 1;
        }
    }
    for i in 0..answer_count { store(output, 8 * i, answers[i]); }
    required as i64
}
