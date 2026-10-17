const MAX_VALUES: usize = 64;
const MAX_INPUT_VALUES: usize = 67;
const MIN_VALUE: i64 = -1_000_000;
const MAX_VALUE: i64 = 1_000_000;

#[derive(Clone, Copy)]
struct Run {
    start: usize,
    length: usize,
    power: i64,
}

fn key_less(left: i64, right: i64, reverse: bool) -> bool {
    if reverse { left > right } else { left < right }
}

fn find_run(values: &mut [i64; MAX_VALUES], start: usize, end: usize, reverse: bool) -> usize {
    if start >= end - 1 { return start + 1; }
    let mut run_end = start + 1;
    if key_less(values[run_end], values[start], reverse) {
        while run_end < end && key_less(values[run_end], values[run_end - 1], reverse) { run_end += 1; }
        values[start..run_end].reverse();
    } else {
        while run_end < end && !key_less(values[run_end], values[run_end - 1], reverse) { run_end += 1; }
    }
    run_end
}

fn node_power(total_length: usize, b1: usize, n1: usize, b2: usize, n2: usize) -> i64 {
    let a = (2 * b1 + n1) as i64;
    let b = (2 * b2 + n2) as i64;
    let denominator = (2 * total_length) as i64;
    let mut power = 0u32;
    while (a * (1i64 << power)) / denominator == (b * (1i64 << power)) / denominator { power += 1; }
    power as i64
}

fn merge_runs(values: &mut [i64; MAX_VALUES], start1: usize, end1: usize, end2: usize, reverse: bool) {
    let left_length = end1 - start1;
    let right_length = end2 - end1;
    let mut left = [0i64; MAX_VALUES];
    let mut right = [0i64; MAX_VALUES];
    left[..left_length].copy_from_slice(&values[start1..end1]);
    right[..right_length].copy_from_slice(&values[end1..end2]);
    let (mut i, mut j, mut output) = (0usize, 0usize, start1);
    while i < left_length && j < right_length {
        let take_left = if reverse { left[i] >= right[j] } else { left[i] <= right[j] };
        if take_left { values[output] = left[i]; i += 1; } else { values[output] = right[j]; j += 1; }
        output += 1;
    }
    while i < left_length { values[output] = left[i]; i += 1; output += 1; }
    while j < right_length { values[output] = right[j]; j += 1; output += 1; }
}

fn power_sort_impl(values: &mut [i64; MAX_VALUES], length: usize, reverse: bool) {
    if length <= 1 { return; }
    let mut stack = [Run { start: 0, length: 0, power: 0 }; MAX_VALUES];
    let mut stack_size = 0usize;
    let mut start = 0usize;
    while start < length {
        let run_end = find_run(values, start, length, reverse);
        let mut run_length = run_end - start;
        let mut power = if stack_size == 0 { 0 } else {
            node_power(length, stack[stack_size - 1].start, stack[stack_size - 1].length, start, run_length)
        };
        while stack_size > 0 && stack[stack_size - 1].power >= power {
            stack_size -= 1;
            let previous = stack[stack_size];
            merge_runs(values, previous.start, previous.start + previous.length, run_end, reverse);
            start = previous.start;
            run_length = run_end - start;
            power = if stack_size == 0 { 0 } else {
                node_power(length, stack[stack_size - 1].start, stack[stack_size - 1].length, start, run_length)
            };
        }
        stack[stack_size] = Run { start, length: run_length, power };
        stack_size += 1;
        start = run_end;
    }
    while stack_size > 1 {
        stack_size -= 1;
        let right = stack[stack_size];
        stack_size -= 1;
        let left = stack[stack_size];
        let merged_end = right.start + right.length;
        merge_runs(values, left.start, left.start + left.length, merged_end, reverse);
        let merged_length = merged_end - left.start;
        let power = if stack_size == 0 { 0 } else {
            node_power(length, stack[stack_size - 1].start, stack[stack_size - 1].length, left.start, merged_length)
        };
        stack[stack_size] = Run { start: left.start, length: merged_length, power };
        stack_size += 1;
    }
}

unsafe fn write_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for (index, byte) in bytes.iter().enumerate() { *output.add(offset + index) = *byte; }
}

#[no_mangle]
pub unsafe extern "C" fn power_sort(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_VALUES { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let reverse_value = values[0];
    let count_value = values[1];
    if (reverse_value != 0 && reverse_value != 1) || !(0..=MAX_VALUES as i64).contains(&count_value) { return -1; }
    let count = count_value as usize;
    if length != 2 + count { return -1; }
    let mut sorted = [0i64; MAX_VALUES];
    for index in 0..count {
        let value = values[2 + index];
        if !(MIN_VALUE..=MAX_VALUE).contains(&value) { return -1; }
        sorted[index] = value;
    }
    if count == 0 { return 0; }
    let output_bytes = 8 * count;
    if output.is_null() || capacity < output_bytes { return -2; }
    power_sort_impl(&mut sorted, count, reverse_value == 1);
    for index in 0..count { write_i64_le(output, index * 8, sorted[index]); }
    output_bytes as i64
}
