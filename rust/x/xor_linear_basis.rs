use std::slice;

const MAX_OPERATIONS: usize = 64;
const MAX_INSERTIONS: usize = 16;
const MAX_INPUT_VALUES: usize = 1 + 2 * MAX_OPERATIONS;
const BIT_COUNT: usize = 63;

fn insert_value(basis: &mut [u64; BIT_COUNT], mut value: u64) {
    for bit in (0..BIT_COUNT).rev() {
        if value == 0 { break; }
        if ((value >> bit) & 1) == 0 { continue; }
        if basis[bit] == 0 {
            basis[bit] = value;
            return;
        }
        value ^= basis[bit];
    }
}

fn maximum_value(basis: &[u64; BIT_COUNT]) -> u64 {
    let mut best = 0u64;
    for bit in (0..BIT_COUNT).rev() {
        let candidate = best ^ basis[bit];
        if candidate > best { best = candidate; }
    }
    best
}

fn contains_value(basis: &[u64; BIT_COUNT], mut value: u64) -> bool {
    for bit in (0..BIT_COUNT).rev() {
        if ((value >> bit) & 1) == 0 { continue; }
        if basis[bit] == 0 { return false; }
        value ^= basis[bit];
    }
    value == 0
}

#[no_mangle]
pub unsafe extern "C" fn xor_linear_basis(
    input_ptr: *const i64, length: usize, output_ptr: *mut u8, capacity: usize,
) -> i64 {
    if input_ptr.is_null() || length < 2 || length > MAX_INPUT_VALUES { return -1; }
    let input = slice::from_raw_parts(input_ptr, length);
    let q_value = input[0];
    if q_value < 1 || q_value > MAX_OPERATIONS as i64 { return -1; }
    let q = q_value as usize;

    let mut basis = [0u64; BIT_COUNT];
    let mut results = [0i64; MAX_OPERATIONS];
    let (mut result_count, mut cursor, mut insertion_count) = (0usize, 1usize, 0usize);
    for _ in 0..q {
        if cursor >= length { return -1; }
        let kind = input[cursor];
        cursor += 1;
        if kind == 0 || kind == 2 {
            if cursor >= length { return -1; }
            let raw_value = input[cursor];
            cursor += 1;
            if raw_value < 0 { return -1; }
            let value = raw_value as u64;
            if kind == 0 {
                insertion_count += 1;
                if insertion_count > MAX_INSERTIONS { return -1; }
                insert_value(&mut basis, value);
            } else {
                results[result_count] = if contains_value(&basis, value) { 1 } else { 0 };
                result_count += 1;
            }
        } else if kind == 1 {
            results[result_count] = maximum_value(&basis) as i64;
            result_count += 1;
        } else {
            return -1;
        }
    }
    if cursor != length { return -1; }
    let output_bytes = result_count * 8;
    if output_bytes == 0 { return 0; }
    if output_ptr.is_null() || capacity < output_bytes { return -2; }
    let output = slice::from_raw_parts_mut(output_ptr, output_bytes);
    for result in 0..result_count {
        output[result * 8..result * 8 + 8]
            .copy_from_slice(&results[result].to_le_bytes());
    }
    output_bytes as i64
}
