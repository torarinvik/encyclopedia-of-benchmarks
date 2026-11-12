use std::slice;

const MAX_N: usize = 32;
const MAX_Q: usize = 32;
const MAX_POINTS: usize = MAX_N + MAX_Q;
const MAX_PARSEABLE_INPUT: usize = 2 + 3 * MAX_N + 5 * MAX_Q + 1;
const MAX_COORD: i64 = 1_000_000;
const MAX_WEIGHT: i64 = 1_000_000;

#[derive(Clone, Copy, Default)]
struct Point { x: i64, y: i64, weight: i64 }
#[derive(Clone, Copy, Default)]
struct Operation { kind: i64, a: i64, b: i64, c: i64, d: i64 }

fn lowbit(value: usize) -> usize { value & value.wrapping_neg() }

fn lower_bound_i64(values: &[i64; MAX_POINTS], count: usize, target: i64) -> usize {
    let (mut left, mut right) = (0, count);
    while left < right {
        let middle = left + (right - left) / 2;
        if values[middle] < target { left = middle + 1; } else { right = middle; }
    }
    left
}

fn lower_bound_usize(values: &[usize], count: usize, target: usize) -> usize {
    let (mut left, mut right) = (0, count);
    while left < right {
        let middle = left + (right - left) / 2;
        if values[middle] < target { left = middle + 1; } else { right = middle; }
    }
    left
}

fn sort_unique(values: &mut [i64; MAX_POINTS], count: usize) -> usize {
    for index in 1..count {
        let value = values[index];
        let mut position = index;
        while position > 0 && values[position - 1] > value {
            values[position] = values[position - 1];
            position -= 1;
        }
        values[position] = value;
    }
    let mut unique_count = 0;
    for index in 0..count {
        if unique_count == 0 || values[index] != values[unique_count - 1] {
            values[unique_count] = values[index];
            unique_count += 1;
        }
    }
    unique_count
}

fn register_coordinate(xs: &[i64; MAX_POINTS], x_count: usize,
    ys: &[i64; MAX_POINTS], y_count: usize,
    present: &mut [bool; (MAX_POINTS + 1) * MAX_POINTS], x: i64, y: i64) {
    let mut outer = lower_bound_i64(xs, x_count, x) + 1;
    let y_rank = lower_bound_i64(ys, y_count, y);
    while outer <= x_count {
        present[outer * MAX_POINTS + y_rank] = true;
        outer += lowbit(outer);
    }
}

fn fenwick_add(tree: &mut [i64; (MAX_POINTS + 1) * (MAX_POINTS + 1)],
    y_values: &[usize; (MAX_POINTS + 1) * MAX_POINTS], y_counts: &[usize; MAX_POINTS + 1],
    x_count: usize, xs: &[i64; MAX_POINTS], ys: &[i64; MAX_POINTS], y_count: usize,
    x: i64, y: i64, weight: i64) {
    let mut outer = lower_bound_i64(xs, x_count, x) + 1;
    let y_rank = lower_bound_i64(ys, y_count, y);
    while outer <= x_count {
        let row = outer * MAX_POINTS;
        let mut inner = lower_bound_usize(&y_values[row..], y_counts[outer], y_rank) + 1;
        while inner <= y_counts[outer] {
            tree[outer * (MAX_POINTS + 1) + inner] += weight;
            inner += lowbit(inner);
        }
        outer += lowbit(outer);
    }
}

fn prefix_sum(tree: &[i64; (MAX_POINTS + 1) * (MAX_POINTS + 1)],
    y_values: &[usize; (MAX_POINTS + 1) * MAX_POINTS], y_counts: &[usize; MAX_POINTS + 1],
    x_count: usize, xs: &[i64; MAX_POINTS], ys: &[i64; MAX_POINTS], y_count: usize,
    x_limit: i64, y_limit: i64) -> i64 {
    let mut outer = lower_bound_i64(xs, x_count, x_limit);
    let y_limit_rank = lower_bound_i64(ys, y_count, y_limit);
    let mut total = 0;
    while outer > 0 {
        let row = outer * MAX_POINTS;
        let mut inner = lower_bound_usize(&y_values[row..], y_counts[outer], y_limit_rank);
        while inner > 0 {
            total += tree[outer * (MAX_POINTS + 1) + inner];
            inner -= lowbit(inner);
        }
        outer -= lowbit(outer);
    }
    total
}

#[no_mangle]
pub unsafe extern "C" fn point_add_rectangle_sum(
    input_ptr: *const i64, length: usize, output_ptr: *mut u8, capacity: usize,
) -> i64 {
    if input_ptr.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT { return -1; }
    let input = slice::from_raw_parts(input_ptr, length);
    let (n_value, q_value) = (input[0], input[1]);
    if !(1..=MAX_N as i64).contains(&n_value) || !(0..=MAX_Q as i64).contains(&q_value) { return -1; }
    let (n, q) = (n_value as usize, q_value as usize);
    let mut initial = [Point::default(); MAX_N];
    let mut operations = [Operation::default(); MAX_Q];
    let mut all_x = [0i64; MAX_POINTS];
    let mut all_y = [0i64; MAX_POINTS];
    let (mut point_count, mut cursor) = (0usize, 2usize);
    for index in 0..n {
        if cursor + 3 > length { return -1; }
        let (x, y, weight) = (input[cursor], input[cursor + 1], input[cursor + 2]);
        cursor += 3;
        if !(0..=MAX_COORD).contains(&x) || !(0..=MAX_COORD).contains(&y) || !(0..=MAX_WEIGHT).contains(&weight) { return -1; }
        initial[index] = Point { x, y, weight };
        all_x[point_count] = x; all_y[point_count] = y; point_count += 1;
    }
    let mut query_count = 0;
    for index in 0..q {
        if cursor >= length { return -1; }
        let kind = input[cursor]; cursor += 1;
        if kind == 0 {
            if cursor + 3 > length { return -1; }
            let (x, y, weight) = (input[cursor], input[cursor + 1], input[cursor + 2]); cursor += 3;
            if !(0..=MAX_COORD).contains(&x) || !(0..=MAX_COORD).contains(&y) || !(0..=MAX_WEIGHT).contains(&weight) { return -1; }
            operations[index] = Operation { kind, a: x, b: y, c: weight, d: 0 };
            all_x[point_count] = x; all_y[point_count] = y; point_count += 1;
        } else if kind == 1 {
            if cursor + 4 > length { return -1; }
            let (left, down, right, up) = (input[cursor], input[cursor + 1], input[cursor + 2], input[cursor + 3]); cursor += 4;
            if left < 0 || left >= right || right > MAX_COORD || down < 0 || down >= up || up > MAX_COORD { return -1; }
            operations[index] = Operation { kind, a: left, b: down, c: right, d: up };
            query_count += 1;
        } else { return -1; }
    }
    if cursor != length { return -1; }

    let x_count = sort_unique(&mut all_x, point_count);
    let y_count = sort_unique(&mut all_y, point_count);
    let mut present = [false; (MAX_POINTS + 1) * MAX_POINTS];
    for point in &initial[..n] { register_coordinate(&all_x, x_count, &all_y, y_count, &mut present, point.x, point.y); }
    for op in &operations[..q] { if op.kind == 0 { register_coordinate(&all_x, x_count, &all_y, y_count, &mut present, op.a, op.b); } }

    let mut y_values = [0usize; (MAX_POINTS + 1) * MAX_POINTS];
    let mut y_counts = [0usize; MAX_POINTS + 1];
    for outer in 1..=x_count { for rank in 0..y_count { if present[outer * MAX_POINTS + rank] {
        y_values[outer * MAX_POINTS + y_counts[outer]] = rank; y_counts[outer] += 1;
    } } }
    let mut tree = [0i64; (MAX_POINTS + 1) * (MAX_POINTS + 1)];
    for point in &initial[..n] { fenwick_add(&mut tree, &y_values, &y_counts, x_count, &all_x, &all_y, y_count, point.x, point.y, point.weight); }
    let mut answers = [0i64; MAX_Q];
    let mut answer_count = 0;
    for op in &operations[..q] {
        if op.kind == 0 { fenwick_add(&mut tree, &y_values, &y_counts, x_count, &all_x, &all_y, y_count, op.a, op.b, op.c); }
        else { answers[answer_count] = prefix_sum(&tree, &y_values, &y_counts, x_count, &all_x, &all_y, y_count, op.c, op.d)
            - prefix_sum(&tree, &y_values, &y_counts, x_count, &all_x, &all_y, y_count, op.a, op.d)
            - prefix_sum(&tree, &y_values, &y_counts, x_count, &all_x, &all_y, y_count, op.c, op.b)
            + prefix_sum(&tree, &y_values, &y_counts, x_count, &all_x, &all_y, y_count, op.a, op.b); answer_count += 1; }
    }
    let output_bytes = 8 * answer_count;
    if output_bytes > 0 && (output_ptr.is_null() || capacity < output_bytes) { return -2; }
    if output_bytes > 0 {
        let output = slice::from_raw_parts_mut(output_ptr, output_bytes);
        for index in 0..answer_count { output[8 * index..8 * index + 8].copy_from_slice(&answers[index].to_le_bytes()); }
    }
    output_bytes as i64
}
