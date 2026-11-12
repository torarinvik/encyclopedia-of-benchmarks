use std::slice;

const MAX_N: usize = 64;
const MAX_Q: usize = 64;
const MAX_VALUES: usize = MAX_N + MAX_Q;
const STRIDE: usize = MAX_N + 1;
const MAX_TREE: usize = MAX_VALUES * STRIDE;
const MAX_PARSEABLE_INPUT: usize = 2 + MAX_N + 4 * MAX_Q + 1;
const MAX_VALUE: i64 = 1_000_000;

#[derive(Clone, Copy, Default)]
struct Operation { kind: i64, a: i64, b: i64, c: i64 }

fn lowbit(value: usize) -> usize { value & value.wrapping_neg() }

fn lower_bound(values: &[i64; MAX_VALUES], count: usize, target: i64) -> usize {
    let (mut left, mut right) = (0, count);
    while left < right {
        let middle = left + (right - left) / 2;
        if values[middle] < target { left = middle + 1; } else { right = middle; }
    }
    left
}

fn sort_unique(values: &mut [i64; MAX_VALUES], count: usize) -> usize {
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

fn fenwick_add(tree: &mut [i64; MAX_TREE], value_id: usize,
    position: usize, n: usize, delta: i64) {
    let row = value_id * STRIDE;
    let mut index = position + 1;
    while index <= n {
        tree[row + index] += delta;
        index += lowbit(index);
    }
}

fn fenwick_prefix(tree: &[i64; MAX_TREE], value_id: usize, count: usize) -> i64 {
    let row = value_id * STRIDE;
    let mut index = count;
    let mut total = 0;
    while index > 0 {
        total += tree[row + index];
        index -= lowbit(index);
    }
    total
}

fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn point_set_range_frequency(
    input_ptr: *const i64, length: usize, output_ptr: *mut u8, capacity: usize,
) -> i64 {
    if input_ptr.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT { return -1; }
    let input = slice::from_raw_parts(input_ptr, length);
    let (n_value, q_value) = (input[0], input[1]);
    if !(1..=MAX_N as i64).contains(&n_value) || !(0..=MAX_Q as i64).contains(&q_value) { return -1; }
    let (n, q) = (n_value as usize, q_value as usize);
    if 2 + n > length { return -1; }
    let mut values = [0i64; MAX_VALUES];
    let mut initial = [0i64; MAX_N];
    let mut operations = [Operation::default(); MAX_Q];
    let mut value_count = 0;
    for index in 0..n {
        let value = input[2 + index];
        if !(0..=MAX_VALUE).contains(&value) { return -1; }
        initial[index] = value;
        values[value_count] = value;
        value_count += 1;
    }
    let (mut cursor, mut query_count) = (2 + n, 0usize);
    for index in 0..q {
        if cursor >= length { return -1; }
        let kind = input[cursor]; cursor += 1;
        if kind == 0 {
            if cursor + 2 > length { return -1; }
            let (position, value) = (input[cursor], input[cursor + 1]);
            cursor += 2;
            if position < 0 || position >= n as i64 || !(0..=MAX_VALUE).contains(&value) { return -1; }
            operations[index] = Operation { kind, a: position, b: value, c: 0 };
            values[value_count] = value;
            value_count += 1;
        } else if kind == 1 {
            if cursor + 3 > length { return -1; }
            let (left, right, value) = (input[cursor], input[cursor + 1], input[cursor + 2]);
            cursor += 3;
            if left < 0 || left > right || right > n as i64 || !(0..=MAX_VALUE).contains(&value) { return -1; }
            operations[index] = Operation { kind, a: left, b: right, c: value };
            query_count += 1;
        } else { return -1; }
    }
    if cursor != length { return -1; }
    let output_bytes = 8 * query_count;
    if output_bytes > 0 && (output_ptr.is_null() || capacity < output_bytes) { return -2; }

    let unique_count = sort_unique(&mut values, value_count);
    let mut tree = [0i64; MAX_TREE];
    let mut current = [0usize; MAX_N];
    for index in 0..n {
        current[index] = lower_bound(&values, unique_count, initial[index]);
        fenwick_add(&mut tree, current[index], index, n, 1);
    }
    let mut answer = 0;
    for operation in &operations[..q] {
        if operation.kind == 0 {
            let position = operation.a as usize;
            let next = lower_bound(&values, unique_count, operation.b);
            if current[position] != next {
                fenwick_add(&mut tree, current[position], position, n, -1);
                fenwick_add(&mut tree, next, position, n, 1);
                current[position] = next;
            }
        } else {
            let id = lower_bound(&values, unique_count, operation.c);
            let mut count = 0;
            if id < unique_count && values[id] == operation.c {
                count = fenwick_prefix(&tree, id, operation.b as usize) -
                        fenwick_prefix(&tree, id, operation.a as usize);
            }
            let output = slice::from_raw_parts_mut(output_ptr, output_bytes);
            store_i64_le(output, 8 * answer, count);
            answer += 1;
        }
    }
    output_bytes as i64
}
