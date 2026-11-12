const MAX_N: usize = 32;
const MAX_Q: usize = 32;
const MAX_POINTS: usize = MAX_N + MAX_Q;
const MAX_TREE: usize = 4 * MAX_POINTS + 8;
const MAX_PARSEABLE_INPUT: usize = 2 + 3 * MAX_N + 7 * MAX_Q + 1;
const MOD: i64 = 998_244_353;
const MAX_COORD: i64 = 1_000_000_000;

#[derive(Clone, Copy, Default)]
struct Operation { kind: i64, a: i64, b: i64, c: i64, d: i64, e: i64, f: i64 }
#[derive(Clone, Copy, Default)]
struct Node {
    min_x: i64, max_x: i64, min_y: i64, max_y: i64,
    sum: i64, lazy_a: i64, lazy_b: i64, active: usize,
}

fn point_less(left: usize, right: usize, xs: &[i64; MAX_POINTS],
              ys: &[i64; MAX_POINTS], axis: usize) -> bool {
    let first = if axis == 0 { xs[left] } else { ys[left] };
    let second = if axis == 0 { xs[right] } else { ys[right] };
    if first != second { return first < second; }
    let first_other = if axis == 0 { ys[left] } else { xs[left] };
    let second_other = if axis == 0 { ys[right] } else { xs[right] };
    if first_other != second_other { return first_other < second_other; }
    left < right
}

fn sort_points(order: &mut [usize; MAX_POINTS], xs: &[i64; MAX_POINTS],
               ys: &[i64; MAX_POINTS], low: usize, high: usize, axis: usize) {
    for i in low + 1..high {
        let point = order[i];
        let mut j = i;
        while j > low && point_less(point, order[j - 1], xs, ys, axis) {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = point;
    }
}

fn build_tree(tree: &mut [Node; MAX_TREE], order: &mut [usize; MAX_POINTS],
              xs: &[i64; MAX_POINTS], ys: &[i64; MAX_POINTS],
              weights: &[i64; MAX_POINTS], rank: &mut [usize; MAX_POINTS],
              low: usize, high: usize, index: usize, depth: usize, initial_n: usize) {
    tree[index].lazy_a = 1;
    if high - low == 1 {
        let point = order[low];
        tree[index].min_x = xs[point]; tree[index].max_x = xs[point];
        tree[index].min_y = ys[point]; tree[index].max_y = ys[point];
        tree[index].active = usize::from(point < initial_n);
        tree[index].sum = if point < initial_n { weights[point] } else { 0 };
        rank[point] = low;
        return;
    }
    sort_points(order, xs, ys, low, high, depth & 1);
    let middle = low + (high - low) / 2;
    build_tree(tree, order, xs, ys, weights, rank, low, middle, index * 2, depth + 1, initial_n);
    build_tree(tree, order, xs, ys, weights, rank, middle, high, index * 2 + 1, depth + 1, initial_n);
    let left = tree[index * 2];
    let right = tree[index * 2 + 1];
    tree[index].min_x = left.min_x.min(right.min_x);
    tree[index].max_x = left.max_x.max(right.max_x);
    tree[index].min_y = left.min_y.min(right.min_y);
    tree[index].max_y = left.max_y.max(right.max_y);
    tree[index].active = left.active + right.active;
    tree[index].sum = (left.sum + right.sum) % MOD;
}

fn apply_node(tree: &mut [Node; MAX_TREE], index: usize, a: i64, b: i64) {
    if tree[index].active == 0 { return; }
    tree[index].sum = (a * tree[index].sum + b * tree[index].active as i64) % MOD;
    tree[index].lazy_a = a * tree[index].lazy_a % MOD;
    tree[index].lazy_b = (a * tree[index].lazy_b + b) % MOD;
}

fn push(tree: &mut [Node; MAX_TREE], index: usize, low: usize, high: usize) {
    if high - low == 1 || (tree[index].lazy_a == 1 && tree[index].lazy_b == 0) { return; }
    let a = tree[index].lazy_a;
    let b = tree[index].lazy_b;
    apply_node(tree, index * 2, a, b);
    apply_node(tree, index * 2 + 1, a, b);
    tree[index].lazy_a = 1;
    tree[index].lazy_b = 0;
}

fn disjoint(node: Node, left: i64, down: i64, right: i64, up: i64) -> bool {
    node.max_x < left || node.min_x >= right || node.max_y < down || node.min_y >= up
}
fn covered(node: Node, left: i64, down: i64, right: i64, up: i64) -> bool {
    left <= node.min_x && node.max_x < right && down <= node.min_y && node.max_y < up
}
fn pull(tree: &mut [Node; MAX_TREE], index: usize) {
    let left = tree[index * 2];
    let right = tree[index * 2 + 1];
    tree[index].sum = (left.sum + right.sum) % MOD;
    tree[index].active = left.active + right.active;
}

fn rectangle_sum(tree: &mut [Node; MAX_TREE], index: usize, low: usize, high: usize,
                 left: i64, down: i64, right: i64, up: i64) -> i64 {
    let node = tree[index];
    if node.active == 0 || disjoint(node, left, down, right, up) { return 0; }
    if covered(node, left, down, right, up) { return node.sum; }
    push(tree, index, low, high);
    let middle = low + (high - low) / 2;
    (rectangle_sum(tree, index * 2, low, middle, left, down, right, up) +
     rectangle_sum(tree, index * 2 + 1, middle, high, left, down, right, up)) % MOD
}

fn rectangle_affine(tree: &mut [Node; MAX_TREE], index: usize, low: usize, high: usize,
                    left: i64, down: i64, right: i64, up: i64, a: i64, b: i64) {
    let node = tree[index];
    if node.active == 0 || disjoint(node, left, down, right, up) { return; }
    if covered(node, left, down, right, up) { apply_node(tree, index, a, b); return; }
    push(tree, index, low, high);
    let middle = low + (high - low) / 2;
    rectangle_affine(tree, index * 2, low, middle, left, down, right, up, a, b);
    rectangle_affine(tree, index * 2 + 1, middle, high, left, down, right, up, a, b);
    pull(tree, index);
}

fn set_point(tree: &mut [Node; MAX_TREE], index: usize, low: usize, high: usize,
             target: usize, weight: i64) {
    if high - low == 1 {
        tree[index].sum = weight;
        tree[index].active = 1;
        tree[index].lazy_a = 1;
        tree[index].lazy_b = 0;
        return;
    }
    push(tree, index, low, high);
    let middle = low + (high - low) / 2;
    if target < middle { set_point(tree, index * 2, low, middle, target, weight); }
    else { set_point(tree, index * 2 + 1, middle, high, target, weight); }
    pull(tree, index);
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn dynamic_point_set_rectangle_affine_rectangle_sum(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT { return -1; }
    let n_value = *input;
    let q_value = *input.add(1);
    if n_value < 1 || n_value > MAX_N as i64 || q_value < 1 || q_value > MAX_Q as i64 { return -1; }
    let n = n_value as usize;
    let q = q_value as usize;
    if 2 + 3 * n > length { return -1; }
    let mut xs = [0i64; MAX_POINTS];
    let mut ys = [0i64; MAX_POINTS];
    let mut weights = [0i64; MAX_POINTS];
    let mut operations = [Operation::default(); MAX_Q];
    for i in 0..n {
        xs[i] = *input.add(2 + 3 * i);
        ys[i] = *input.add(3 + 3 * i);
        weights[i] = *input.add(4 + 3 * i);
        if xs[i] < 0 || xs[i] > MAX_COORD || ys[i] < 0 || ys[i] > MAX_COORD ||
            weights[i] < 0 || weights[i] >= MOD { return -1; }
    }
    let mut point_count = n;
    let mut active_count = n;
    let mut query_count = 0usize;
    let mut cursor = 2 + 3 * n;
    for operation in 0..q {
        if cursor >= length { return -1; }
        let kind = *input.add(cursor); cursor += 1;
        if kind == 0 {
            if cursor + 3 > length || point_count >= MAX_POINTS { return -1; }
            let x = *input.add(cursor); let y = *input.add(cursor + 1); let weight = *input.add(cursor + 2);
            cursor += 3;
            if x < 0 || x > MAX_COORD || y < 0 || y > MAX_COORD || weight < 0 || weight >= MOD { return -1; }
            xs[point_count] = x; ys[point_count] = y;
            operations[operation] = Operation { kind, a: point_count as i64, b: weight, ..Operation::default() };
            point_count += 1; active_count += 1;
        } else if kind == 1 {
            if cursor + 2 > length { return -1; }
            let point = *input.add(cursor); let weight = *input.add(cursor + 1); cursor += 2;
            if point < 0 || point >= active_count as i64 || weight < 0 || weight >= MOD { return -1; }
            operations[operation] = Operation { kind, a: point, b: weight, ..Operation::default() };
        } else if kind == 2 || kind == 3 {
            let fields = if kind == 2 { 4 } else { 6 };
            if cursor + fields > length { return -1; }
            let left = *input.add(cursor); let down = *input.add(cursor + 1);
            let right = *input.add(cursor + 2); let up = *input.add(cursor + 3);
            if left < 0 || left >= right || right > MAX_COORD || down < 0 || down >= up || up > MAX_COORD { return -1; }
            if kind == 2 {
                cursor += 4;
                operations[operation] = Operation { kind, a: left, b: down, c: right, d: up, ..Operation::default() };
                query_count += 1;
            } else {
                let a = *input.add(cursor + 4); let b = *input.add(cursor + 5); cursor += 6;
                if a < 0 || a >= MOD || b < 0 || b >= MOD { return -1; }
                operations[operation] = Operation { kind, a: left, b: down, c: right, d: up, e: a, f: b };
            }
        } else { return -1; }
    }
    if cursor != length { return -1; }
    let output_bytes = 8 * query_count;
    if output_bytes > 0 && (output.is_null() || capacity < output_bytes) { return -2; }

    let mut tree = [Node::default(); MAX_TREE];
    let mut order = [0usize; MAX_POINTS];
    let mut rank = [0usize; MAX_POINTS];
    for i in 0..point_count { order[i] = i; }
    build_tree(&mut tree, &mut order, &xs, &ys, &weights, &mut rank, 0, point_count, 1, 0, n);
    let mut answers = [0i64; MAX_Q];
    let mut answer_count = 0usize;
    for operation in 0..q {
        let op = operations[operation];
        if op.kind == 0 || op.kind == 1 {
            set_point(&mut tree, 1, 0, point_count, rank[op.a as usize], op.b);
        } else if op.kind == 2 {
            answers[answer_count] = rectangle_sum(&mut tree, 1, 0, point_count, op.a, op.b, op.c, op.d);
            answer_count += 1;
        } else {
            rectangle_affine(&mut tree, 1, 0, point_count, op.a, op.b, op.c, op.d, op.e, op.f);
        }
    }
    for i in 0..answer_count { store_i64_le(output, 8 * i, answers[i]); }
    output_bytes as i64
}
