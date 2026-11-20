use std::slice;

const MAX_N: usize = 256;

struct IntervalState<'a> {
    output: &'a mut [u8],
    count: usize,
    last_hi: usize,
    last_value: i32,
    has_last: bool,
}

fn value_at(index: usize, step: i64, offset: i64, divisor: i64) -> i32 {
    ((step * index as i64 + offset) / divisor) as i32
}

fn store_i32_le(output: &mut [u8], position: usize, value: i32) {
    output[position..position + 4].copy_from_slice(&value.to_le_bytes());
}

fn append_interval(state: &mut IntervalState<'_>, lo: usize, hi: usize, value: i32) {
    if state.has_last && state.last_hi == lo && state.last_value == value {
        store_i32_le(state.output, (state.count - 1) * 12 + 4, hi as i32);
    } else {
        let position = state.count * 12;
        store_i32_le(state.output, position, lo as i32);
        store_i32_le(state.output, position + 4, hi as i32);
        store_i32_le(state.output, position + 8, value);
        state.count += 1;
    }
    state.last_hi = hi;
    state.last_value = value;
    state.has_last = true;
}

fn visit_range(lo: usize, hi: usize, step: i64, offset: i64, divisor: i64,
               state: &mut IntervalState<'_>) {
    let first = value_at(lo, step, offset, divisor);
    let last = value_at(hi - 1, step, offset, divisor);
    if first == last || hi - lo == 1 {
        append_interval(state, lo, hi, first);
        return;
    }
    let mid = lo + (hi - lo) / 2;
    visit_range(lo, mid, step, offset, divisor, state);
    visit_range(mid, hi, step, offset, divisor, state);
}

#[no_mangle]
pub unsafe extern "C" fn constant_intervals(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length != 4 { return -1; }
    let values = slice::from_raw_parts(input, length);
    let n_value = values[0];
    let step = values[1];
    let offset = values[2];
    let divisor = values[3];
    if n_value < 0 || n_value > MAX_N as i64 || !(0..=65535).contains(&step)
        || !(0..=65535).contains(&offset) || !(1..=65535).contains(&divisor) { return -1; }
    let n = n_value as usize;
    let maximum_bytes = n * 12;
    if output_capacity < maximum_bytes || (maximum_bytes > 0 && output.is_null()) { return -2; }
    if n == 0 { return 0; }
    let output_slice = slice::from_raw_parts_mut(output, maximum_bytes);
    let mut state = IntervalState { output: output_slice, count: 0, last_hi: 0, last_value: 0, has_last: false };
    visit_range(0, n, step, offset, divisor, &mut state);
    state.count as i64
}
