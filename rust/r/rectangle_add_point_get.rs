use std::slice;

const MAX_N: usize = 32;
const MAX_Q: usize = 32;
const MAX_RECTANGLES: usize = MAX_N + MAX_Q;
const MAX_COORDS: usize = 2 * MAX_RECTANGLES;
const MAX_CORNERS: usize = 4 * MAX_RECTANGLES;
const MAX_PARSEABLE_INPUT: usize = 2 + 5 * MAX_N + 6 * MAX_Q + 1;
const MAX_COORD: i64 = 1_000_000;
const MAX_WEIGHT: i64 = 1_000_000;

#[derive(Clone, Copy, Default)]
struct Rectangle { left: i64, down: i64, right: i64, up: i64, weight: i64 }
#[derive(Clone, Copy, Default)]
struct Operation { kind: i64, a: i64, b: i64, c: i64, d: i64, e: i64 }

fn lowbit(value: usize) -> usize { value & value.wrapping_neg() }

fn lower_bound_i64(values: &[i64; MAX_CORNERS], count: usize, target: i64) -> usize {
    let (mut left, mut right) = (0, count);
    while left < right {
        let middle = left + (right - left) / 2;
        if values[middle] < target { left = middle + 1; } else { right = middle; }
    }
    left
}

fn upper_bound_i64(values: &[i64; MAX_CORNERS], count: usize, target: i64) -> usize {
    let (mut left, mut right) = (0, count);
    while left < right {
        let middle = left + (right - left) / 2;
        if values[middle] <= target { left = middle + 1; } else { right = middle; }
    }
    left
}

fn lower_bound_usize(values: &[usize], target: usize) -> usize {
    let (mut left, mut right) = (0, values.len());
    while left < right {
        let middle = left + (right - left) / 2;
        if values[middle] < target { left = middle + 1; } else { right = middle; }
    }
    left
}

fn sort_unique(values: &mut [i64; MAX_CORNERS], count: usize) -> usize {
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

type Presence = [bool; (MAX_COORDS + 1) * MAX_COORDS];
type NestedValues = [usize; (MAX_COORDS + 1) * MAX_COORDS];
type NestedTree = [i64; (MAX_COORDS + 1) * (MAX_COORDS + 1)];

fn register_event(xs: &[i64; MAX_CORNERS], x_count: usize,
    ys: &[i64; MAX_CORNERS], y_count: usize, present: &mut Presence,
    x: i64, y: i64) {
    let mut outer = lower_bound_i64(xs, x_count, x) + 1;
    let rank = lower_bound_i64(ys, y_count, y);
    while outer <= x_count {
        present[outer * MAX_COORDS + rank] = true;
        outer += lowbit(outer);
    }
}

fn register_rectangle(xs: &[i64; MAX_CORNERS], x_count: usize,
    ys: &[i64; MAX_CORNERS], y_count: usize, present: &mut Presence,
    rectangle: Rectangle) {
    register_event(xs, x_count, ys, y_count, present, rectangle.left, rectangle.down);
    register_event(xs, x_count, ys, y_count, present, rectangle.right, rectangle.down);
    register_event(xs, x_count, ys, y_count, present, rectangle.left, rectangle.up);
    register_event(xs, x_count, ys, y_count, present, rectangle.right, rectangle.up);
}

fn fenwick_add(tree: &mut NestedTree, y_values: &NestedValues,
    y_counts: &[usize; MAX_COORDS + 1], xs: &[i64; MAX_CORNERS], x_count: usize,
    ys: &[i64; MAX_CORNERS], y_count: usize, x: i64, y: i64, weight: i64) {
    let mut outer = lower_bound_i64(xs, x_count, x) + 1;
    let y_rank = lower_bound_i64(ys, y_count, y);
    while outer <= x_count {
        let row = outer * MAX_COORDS;
        let mut inner = lower_bound_usize(&y_values[row..row + y_counts[outer]], y_rank) + 1;
        while inner <= y_counts[outer] {
            tree[outer * (MAX_COORDS + 1) + inner] += weight;
            inner += lowbit(inner);
        }
        outer += lowbit(outer);
    }
}

fn apply_rectangle(tree: &mut NestedTree, y_values: &NestedValues,
    y_counts: &[usize; MAX_COORDS + 1], xs: &[i64; MAX_CORNERS], x_count: usize,
    ys: &[i64; MAX_CORNERS], y_count: usize, rectangle: Rectangle) {
    let weight = rectangle.weight;
    fenwick_add(tree, y_values, y_counts, xs, x_count, ys, y_count,
        rectangle.left, rectangle.down, weight);
    fenwick_add(tree, y_values, y_counts, xs, x_count, ys, y_count,
        rectangle.right, rectangle.down, -weight);
    fenwick_add(tree, y_values, y_counts, xs, x_count, ys, y_count,
        rectangle.left, rectangle.up, -weight);
    fenwick_add(tree, y_values, y_counts, xs, x_count, ys, y_count,
        rectangle.right, rectangle.up, weight);
}

fn prefix_sum(tree: &NestedTree, y_values: &NestedValues,
    y_counts: &[usize; MAX_COORDS + 1], xs: &[i64; MAX_CORNERS], x_count: usize,
    ys: &[i64; MAX_CORNERS], y_count: usize, x_limit: i64, y_limit: i64) -> i64 {
    let mut outer = upper_bound_i64(xs, x_count, x_limit);
    let y_limit_rank = upper_bound_i64(ys, y_count, y_limit);
    let mut total = 0;
    while outer > 0 {
        let row = outer * MAX_COORDS;
        let mut inner = lower_bound_usize(&y_values[row..row + y_counts[outer]], y_limit_rank);
        while inner > 0 {
            total += tree[outer * (MAX_COORDS + 1) + inner];
            inner -= lowbit(inner);
        }
        outer -= lowbit(outer);
    }
    total
}

#[no_mangle]
pub unsafe extern "C" fn rectangle_add_point_get(
    input_ptr: *const i64, length: usize, output_ptr: *mut u8, capacity: usize,
) -> i64 {
    if input_ptr.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT { return -1; }
    let input = slice::from_raw_parts(input_ptr, length);
    let (n_value, q_value) = (input[0], input[1]);
    if !(1..=MAX_N as i64).contains(&n_value) || !(1..=MAX_Q as i64).contains(&q_value) { return -1; }
    let (n, q) = (n_value as usize, q_value as usize);
    let mut initial = [Rectangle::default(); MAX_N];
    let mut operations = [Operation::default(); MAX_Q];
    let mut all_x = [0i64; MAX_CORNERS];
    let mut all_y = [0i64; MAX_CORNERS];
    let (mut rectangle_count, mut cursor) = (0usize, 2usize);
    for index in 0..n {
        if cursor + 5 > length { return -1; }
        let rectangle = Rectangle { left: input[cursor], down: input[cursor + 1],
            right: input[cursor + 2], up: input[cursor + 3], weight: input[cursor + 4] };
        cursor += 5;
        if rectangle.left < 0 || rectangle.left >= rectangle.right || rectangle.right > MAX_COORD ||
            rectangle.down < 0 || rectangle.down >= rectangle.up || rectangle.up > MAX_COORD ||
            rectangle.weight < 0 || rectangle.weight > MAX_WEIGHT { return -1; }
        initial[index] = rectangle;
        let corner_x = [rectangle.left, rectangle.right, rectangle.left, rectangle.right];
        let corner_y = [rectangle.down, rectangle.down, rectangle.up, rectangle.up];
        for corner in 0..4 {
            all_x[rectangle_count * 4 + corner] = corner_x[corner];
            all_y[rectangle_count * 4 + corner] = corner_y[corner];
        }
        rectangle_count += 1;
    }
    for index in 0..q {
        if cursor >= length { return -1; }
        let kind = input[cursor]; cursor += 1;
        if kind == 0 {
            if cursor + 5 > length { return -1; }
            let rectangle = Rectangle { left: input[cursor], down: input[cursor + 1],
                right: input[cursor + 2], up: input[cursor + 3], weight: input[cursor + 4] };
            cursor += 5;
            if rectangle.left < 0 || rectangle.left >= rectangle.right || rectangle.right > MAX_COORD ||
                rectangle.down < 0 || rectangle.down >= rectangle.up || rectangle.up > MAX_COORD ||
                rectangle.weight < 0 || rectangle.weight > MAX_WEIGHT { return -1; }
            operations[index] = Operation { kind, a: rectangle.left, b: rectangle.down,
                c: rectangle.right, d: rectangle.up, e: rectangle.weight };
            let corner_x = [rectangle.left, rectangle.right, rectangle.left, rectangle.right];
            let corner_y = [rectangle.down, rectangle.down, rectangle.up, rectangle.up];
            for corner in 0..4 {
                all_x[rectangle_count * 4 + corner] = corner_x[corner];
                all_y[rectangle_count * 4 + corner] = corner_y[corner];
            }
            rectangle_count += 1;
        } else if kind == 1 {
            if cursor + 2 > length { return -1; }
            let (x, y) = (input[cursor], input[cursor + 1]); cursor += 2;
            if !(0..=MAX_COORD).contains(&x) || !(0..=MAX_COORD).contains(&y) { return -1; }
            operations[index] = Operation { kind, a: x, b: y, c: 0, d: 0, e: 0 };
        } else { return -1; }
    }
    if cursor != length { return -1; }

    let corner_count = rectangle_count * 4;
    let x_count = sort_unique(&mut all_x, corner_count);
    let y_count = sort_unique(&mut all_y, corner_count);
    let mut present = [false; (MAX_COORDS + 1) * MAX_COORDS];
    for rectangle in &initial[..n] { register_rectangle(&all_x, x_count, &all_y, y_count, &mut present, *rectangle); }
    for operation in &operations[..q] { if operation.kind == 0 {
        register_rectangle(&all_x, x_count, &all_y, y_count, &mut present,
            Rectangle { left: operation.a, down: operation.b, right: operation.c,
                up: operation.d, weight: operation.e });
    } }
    let mut y_values = [0usize; (MAX_COORDS + 1) * MAX_COORDS];
    let mut y_counts = [0usize; MAX_COORDS + 1];
    for outer in 1..=x_count { for rank in 0..y_count { if present[outer * MAX_COORDS + rank] {
        y_values[outer * MAX_COORDS + y_counts[outer]] = rank; y_counts[outer] += 1;
    } } }
    let mut tree = [0i64; (MAX_COORDS + 1) * (MAX_COORDS + 1)];
    for rectangle in &initial[..n] {
        apply_rectangle(&mut tree, &y_values, &y_counts, &all_x, x_count,
            &all_y, y_count, *rectangle);
    }
    let mut answers = [0i64; MAX_Q];
    let mut answer_count = 0;
    for operation in &operations[..q] {
        if operation.kind == 0 {
            apply_rectangle(&mut tree, &y_values, &y_counts, &all_x, x_count,
                &all_y, y_count, Rectangle { left: operation.a, down: operation.b,
                    right: operation.c, up: operation.d, weight: operation.e });
        } else {
            answers[answer_count] = prefix_sum(&tree, &y_values, &y_counts, &all_x,
                x_count, &all_y, y_count, operation.a, operation.b);
            answer_count += 1;
        }
    }
    let output_bytes = 8 * answer_count;
    if output_bytes > 0 && (output_ptr.is_null() || capacity < output_bytes) { return -2; }
    if output_bytes > 0 {
        let output = slice::from_raw_parts_mut(output_ptr, output_bytes);
        for index in 0..answer_count { output[8 * index..8 * index + 8].copy_from_slice(&answers[index].to_le_bytes()); }
    }
    output_bytes as i64
}
