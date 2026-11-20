//! Clean-room bounded Bagwell two-dimensional VArray profile.

use std::slice;

const MAX_N: usize = 321;
const MAX_Q: usize = 256;
const DATA_SLOTS: usize = 352;
const POINTER_SLOTS: usize = 56;
const LEVEL_HEADERS: usize = 3;

fn level_start(level: usize) -> usize {
    [0, 64, 320][level]
}

fn locate(level: usize, index: usize) -> (usize, usize, usize) {
    let (value_start, side, pointer_start, data_start) = match level {
        0 => (0, 8, 0, 0),
        1 => (64, 16, 8, 64),
        _ => (320, 32, 24, 320),
    };
    let relative = index - value_start;
    let child = relative / side;
    (pointer_start + child, data_start + child * side, relative % side)
}

fn find_level(index: usize, current_header: usize, previous_header: &[i64; LEVEL_HEADERS]) -> i64 {
    let mut level = current_header as i64;
    while level >= 0 && index < level_start(level as usize) {
        level = previous_header[level as usize];
    }
    level
}

unsafe fn put_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for (byte, value) in bytes.iter().enumerate() {
        output.add(offset + byte).write(*value);
    }
}

#[no_mangle]
pub unsafe extern "C" fn bagwell_varray_growth_index(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=580).contains(&length) { return -1; }
    let values = slice::from_raw_parts(input, length);
    let n_value = values[0];
    let q_value = values[1];
    if !(0..=MAX_N as i64).contains(&n_value) || !(0..=MAX_Q as i64).contains(&q_value) {
        return -1;
    }
    let n = n_value as usize;
    let q = q_value as usize;
    if (n == 0 && q != 0) || length != 2 + n + q { return -1; }
    let query_start = 2 + n;
    if values[query_start..].iter().any(|&index| index < 0 || index as usize >= n) {
        return -1;
    }

    let mut data = [0_i64; DATA_SLOTS];
    let mut pointers = [-1_i64; POINTER_SLOTS];
    let mut previous_header = [-1_i64; LEVEL_HEADERS];
    let mut current_header = 0_usize;
    for index in 0..n {
        if index == 64 || index == 320 {
            let next_header = current_header + 1;
            previous_header[next_header] = current_header as i64;
            current_header = next_header;
        }
        let (pointer_slot, child_base, element_offset) = locate(current_header, index);
        if pointers[pointer_slot] == -1 { pointers[pointer_slot] = child_base as i64; }
        if pointers[pointer_slot] != child_base as i64 || child_base + element_offset >= DATA_SLOTS {
            return -1;
        }
        data[pointers[pointer_slot] as usize + element_offset] = values[2 + index];
    }

    let output_bytes = 8 * (q + 1);
    if output.is_null() || capacity < output_bytes { return -2; }
    put_i64_le(output, 0, q_value);
    for query in 0..q {
        let index = values[query_start + query] as usize;
        let level = find_level(index, current_header, &previous_header);
        let (pointer_slot, _, element_offset) = locate(level as usize, index);
        let value = data[pointers[pointer_slot] as usize + element_offset];
        put_i64_le(output, 8 * (query + 1), value);
    }
    output_bytes as i64
}
