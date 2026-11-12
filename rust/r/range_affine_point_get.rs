use std::slice;

const MAX_N: usize = 256;
const MAX_Q: usize = 256;
const MAX_BASE: usize = 256;
const MAX_TREE: usize = 2 * MAX_BASE;
const MAX_PARSEABLE_INPUT: usize = 2 + MAX_N + 5 * MAX_Q + 1;
const MODULUS: i64 = 998_244_353;

#[derive(Clone, Copy, Default)]
struct Operation { kind: i64, left: i64, right: i64, multiplier: i64, offset: i64 }

fn apply_tag(mul: &mut [i64; MAX_TREE], add: &mut [i64; MAX_TREE], node: usize,
             multiplier: i64, offset: i64) {
    add[node] = (multiplier * add[node] + offset) % MODULUS;
    mul[node] = (multiplier * mul[node]) % MODULUS;
}

fn push(mul: &mut [i64; MAX_TREE], add: &mut [i64; MAX_TREE], node: usize) {
    if mul[node] != 1 || add[node] != 0 {
        let (m, a) = (mul[node], add[node]);
        apply_tag(mul, add, 2 * node, m, a);
        apply_tag(mul, add, 2 * node + 1, m, a);
        mul[node] = 1;
        add[node] = 0;
    }
}

fn range_apply(mul: &mut [i64; MAX_TREE], add: &mut [i64; MAX_TREE],
    node: usize, segment_left: usize, segment_right: usize,
    left: usize, right: usize, multiplier: i64, offset: i64) {
    if right <= segment_left || segment_right <= left { return; }
    if left <= segment_left && segment_right <= right {
        apply_tag(mul, add, node, multiplier, offset);
        return;
    }
    push(mul, add, node);
    let middle = segment_left + (segment_right - segment_left) / 2;
    range_apply(mul, add, 2 * node, segment_left, middle, left, right, multiplier, offset);
    range_apply(mul, add, 2 * node + 1, middle, segment_right, left, right, multiplier, offset);
}

fn point_get(mul: &mut [i64; MAX_TREE], add: &mut [i64; MAX_TREE],
    initial: &[i64; MAX_N], node: usize, segment_left: usize,
    segment_right: usize, index: usize) -> i64 {
    if segment_right - segment_left == 1 {
        return (mul[node] * initial[index] + add[node]) % MODULUS;
    }
    push(mul, add, node);
    let middle = segment_left + (segment_right - segment_left) / 2;
    if index < middle {
        point_get(mul, add, initial, 2 * node, segment_left, middle, index)
    } else {
        point_get(mul, add, initial, 2 * node + 1, middle, segment_right, index)
    }
}

fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn range_affine_point_get(
    input_ptr: *const i64, length: usize, output_ptr: *mut u8, capacity: usize,
) -> i64 {
    if input_ptr.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT { return -1; }
    let input = slice::from_raw_parts(input_ptr, length);
    let (n_value, q_value) = (input[0], input[1]);
    if !(1..=MAX_N as i64).contains(&n_value) || !(0..=MAX_Q as i64).contains(&q_value) { return -1; }
    let (n, q) = (n_value as usize, q_value as usize);
    if 2 + n > length { return -1; }
    let mut initial = [0i64; MAX_N];
    let mut operations = [Operation::default(); MAX_Q];
    for index in 0..n {
        initial[index] = input[2 + index];
        if !(0..MODULUS).contains(&initial[index]) { return -1; }
    }
    let (mut cursor, mut query_count) = (2 + n, 0usize);
    for index in 0..q {
        if cursor >= length { return -1; }
        let kind = input[cursor]; cursor += 1;
        if kind == 0 {
            if cursor + 4 > length { return -1; }
            let (left, right, multiplier, offset) =
                (input[cursor], input[cursor + 1], input[cursor + 2], input[cursor + 3]);
            cursor += 4;
            if left < 0 || left >= right || right > n as i64 ||
                multiplier < 1 || multiplier >= MODULUS || offset < 0 || offset >= MODULUS { return -1; }
            operations[index] = Operation { kind, left, right, multiplier, offset };
        } else if kind == 1 {
            if cursor >= length { return -1; }
            let point = input[cursor]; cursor += 1;
            if point < 0 || point >= n as i64 { return -1; }
            operations[index] = Operation { kind, left: point, ..Operation::default() };
            query_count += 1;
        } else { return -1; }
    }
    if cursor != length { return -1; }
    let output_bytes = 8 * query_count;
    if output_bytes > 0 && (output_ptr.is_null() || capacity < output_bytes) { return -2; }

    let mut base = 1usize;
    while base < n { base *= 2; }
    let mut mul = [1i64; MAX_TREE];
    let mut add = [0i64; MAX_TREE];
    let mut answer = 0usize;
    for operation in &operations[..q] {
        if operation.kind == 0 {
            range_apply(&mut mul, &mut add, 1, 0, base,
                operation.left as usize, operation.right as usize,
                operation.multiplier, operation.offset);
        } else {
            let value = point_get(&mut mul, &mut add, &initial, 1, 0, base,
                                  operation.left as usize);
            let output = slice::from_raw_parts_mut(output_ptr, output_bytes);
            store_i64_le(output, 8 * answer, value);
            answer += 1;
        }
    }
    output_bytes as i64
}
