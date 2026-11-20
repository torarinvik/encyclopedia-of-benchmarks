const MAX_N: usize = 64;
const MAX_INPUT: usize = 67;
const MAX_SEGMENTS: usize = 65;

fn gcd_nonnegative(mut a: i64, mut b: i64) -> i64 {
    while b != 0 {
        let remainder = a % b;
        a = b;
        b = remainder;
    }
    a
}

fn combine_value(mode: i64, a: i64, b: i64) -> i64 {
    match mode {
        0 => gcd_nonnegative(a, b),
        1 => a | b,
        _ => a & b,
    }
}

fn solve(input: &[i64]) -> i64 {
    if input.len() < 2 || input.len() > MAX_INPUT { return -1; }
    let mode = input[0];
    let n_value = input[1];
    if !(0..=2).contains(&mode) || !(0..=MAX_N as i64).contains(&n_value) { return -1; }
    let n = n_value as usize;
    if input.len() != 2 + n { return -1; }

    let mut segment_value = [0i64; MAX_SEGMENTS];
    let mut segment_left = [0i64; MAX_SEGMENTS];
    let mut segment_right = [0i64; MAX_SEGMENTS];
    let mut segment_count = 0usize;
    let mut aggregate_sum = 0i64;
    let mut suffix_distinct_count = 0i64;
    for right in 0..n {
        let value = input[2 + right];
        if !(0..=255).contains(&value) { return -1; }
        for j in 0..segment_count {
            segment_value[j] = combine_value(mode, segment_value[j], value);
        }
        segment_value[segment_count] = value;
        segment_left[segment_count] = right as i64;
        segment_right[segment_count] = right as i64;
        segment_count += 1;

        let mut write = 0usize;
        for read in 0..segment_count {
            if write > 0 && segment_value[read] == segment_value[write - 1] {
                segment_right[write - 1] = segment_right[read];
            } else {
                segment_value[write] = segment_value[read];
                segment_left[write] = segment_left[read];
                segment_right[write] = segment_right[read];
                write += 1;
            }
        }
        segment_count = write;
        suffix_distinct_count += segment_count as i64;
        for j in 0..segment_count {
            aggregate_sum += segment_value[j] * (segment_right[j] - segment_left[j] + 1);
        }
    }
    aggregate_sum * 1024 + suffix_distinct_count
}

#[no_mangle]
pub unsafe extern "C" fn distinct_subarray_aggregates(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
