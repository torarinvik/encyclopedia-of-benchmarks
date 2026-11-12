const MAX_QUERIES: usize = 128;
const MAX_RUNS: usize = 64;
const MAX_INPUT_LENGTH: usize = 16_384;
const MAX_OUTPUT_WORDS: usize = 32_768;
const MAX_COMPONENT: i64 = 1_000_000_000;

#[derive(Clone, Copy, Default)]
struct Run {
    direction: i64,
    count: i64,
}

#[derive(Clone, Copy)]
struct Decoded {
    numerator: i64,
    denominator: i64,
    lower_num: i64,
    lower_den: i64,
    upper_num: i64,
    upper_den: i64,
}

fn gcd(mut a: i64, mut b: i64) -> i64 {
    while b != 0 {
        let remainder = a % b;
        a = b;
        b = remainder;
    }
    a
}

fn valid_fraction(numerator: i64, denominator: i64) -> bool {
    numerator >= 1 && numerator <= MAX_COMPONENT
        && denominator >= 1 && denominator <= MAX_COMPONENT
        && gcd(numerator, denominator) == 1
}

fn encode_path(mut numerator: i64, mut denominator: i64, runs: &mut [Run; MAX_RUNS]) -> Option<usize> {
    let mut run_count = 0;
    while numerator != denominator {
        if run_count >= MAX_RUNS { return None; }
        if numerator < denominator {
            let count = (denominator - 1) / numerator;
            runs[run_count] = Run { direction: 0, count };
            denominator -= count * numerator;
        } else {
            let count = (numerator - 1) / denominator;
            runs[run_count] = Run { direction: 1, count };
            numerator -= count * denominator;
        }
        run_count += 1;
    }
    Some(run_count)
}

fn decode_path(runs: &[Run]) -> Option<Decoded> {
    let (mut ln, mut ld, mut un, mut ud) = (0i64, 1i64, 1i64, 0i64);
    let mut previous = -1;
    for run in runs {
        if (run.direction != 0 && run.direction != 1) || run.count < 1
            || run.count > MAX_COMPONENT || run.direction == previous { return None; }
        if run.direction == 0 {
            un += run.count * ln;
            ud += run.count * ld;
            if un > MAX_COMPONENT || ud > MAX_COMPONENT { return None; }
        } else {
            ln += run.count * un;
            ld += run.count * ud;
            if ln > MAX_COMPONENT || ld > MAX_COMPONENT { return None; }
        }
        previous = run.direction;
    }
    let numerator = ln + un;
    let denominator = ld + ud;
    if !valid_fraction(numerator, denominator) { return None; }
    Some(Decoded { numerator, denominator, lower_num: ln, lower_den: ld,
                   upper_num: un, upper_den: ud })
}

fn append_common_prefix(left: &[Run], right: &[Run], prefix: &mut [Run; MAX_RUNS]) -> usize {
    let (mut i, mut j, mut left_used, mut right_used, mut count) = (0usize, 0usize, 0i64, 0i64, 0usize);
    while i < left.len() && j < right.len() && left[i].direction == right[j].direction {
        let left_remaining = left[i].count - left_used;
        let right_remaining = right[j].count - right_used;
        let shared = left_remaining.min(right_remaining);
        prefix[count] = Run { direction: left[i].direction, count: shared };
        count += 1;
        left_used += shared;
        right_used += shared;
        if left_used == left[i].count { i += 1; left_used = 0; }
        if right_used == right[j].count { j += 1; right_used = 0; }
    }
    count
}

fn append(words: &mut [i64; MAX_OUTPUT_WORDS], length: &mut usize, value: i64) -> bool {
    if *length >= MAX_OUTPUT_WORDS { return false; }
    words[*length] = value;
    *length += 1;
    true
}

/// Execute a bounded batch of Stern–Brocot path and ancestor queries.
#[no_mangle]
pub unsafe extern "C" fn stern_brocot_tree(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = core::slice::from_raw_parts(input, length);
    let query_count = values[0];
    if query_count < 1 || query_count > MAX_QUERIES as i64 { return -1; }
    let (mut position, mut word_count) = (1usize, 0usize);
    let mut words = [0i64; MAX_OUTPUT_WORDS];
    for _ in 0..query_count {
        if position >= length { return -1; }
        let operation = values[position];
        position += 1;
        if operation == 0 {
            if position + 2 > length { return -1; }
            let (numerator, denominator) = (values[position], values[position + 1]);
            position += 2;
            if !valid_fraction(numerator, denominator) { return -1; }
            let mut runs = [Run::default(); MAX_RUNS];
            let Some(run_count) = encode_path(numerator, denominator, &mut runs) else { return -1; };
            if !append(&mut words, &mut word_count, operation)
                || !append(&mut words, &mut word_count, run_count as i64) { return -1; }
            for run in &runs[..run_count] {
                if !append(&mut words, &mut word_count, run.direction)
                    || !append(&mut words, &mut word_count, run.count) { return -1; }
            }
        } else if operation == 1 {
            if position >= length { return -1; }
            let raw_count = values[position];
            position += 1;
            if raw_count < 0 || raw_count > MAX_RUNS as i64 { return -1; }
            let run_count = raw_count as usize;
            if position + 2 * run_count > length { return -1; }
            let mut runs = [Run::default(); MAX_RUNS];
            for run in &mut runs[..run_count] {
                *run = Run { direction: values[position], count: values[position + 1] };
                position += 2;
            }
            let Some(decoded) = decode_path(&runs[..run_count]) else { return -1; };
            if !append(&mut words, &mut word_count, operation)
                || !append(&mut words, &mut word_count, decoded.numerator)
                || !append(&mut words, &mut word_count, decoded.denominator) { return -1; }
        } else if operation == 2 {
            if position + 4 > length { return -1; }
            let (a, b, c, d) = (values[position], values[position + 1],
                               values[position + 2], values[position + 3]);
            position += 4;
            if !valid_fraction(a, b) || !valid_fraction(c, d) { return -1; }
            let (mut left, mut right, mut prefix) = ([Run::default(); MAX_RUNS],
                                                       [Run::default(); MAX_RUNS],
                                                       [Run::default(); MAX_RUNS]);
            let Some(left_count) = encode_path(a, b, &mut left) else { return -1; };
            let Some(right_count) = encode_path(c, d, &mut right) else { return -1; };
            let prefix_count = append_common_prefix(&left[..left_count], &right[..right_count], &mut prefix);
            let Some(decoded) = decode_path(&prefix[..prefix_count]) else { return -1; };
            if !append(&mut words, &mut word_count, operation)
                || !append(&mut words, &mut word_count, decoded.numerator)
                || !append(&mut words, &mut word_count, decoded.denominator) { return -1; }
        } else if operation == 3 {
            if position + 3 > length { return -1; }
            let (depth, numerator, denominator) = (values[position], values[position + 1], values[position + 2]);
            position += 3;
            if depth < 1 || depth > MAX_COMPONENT || !valid_fraction(numerator, denominator) { return -1; }
            let mut path = [Run::default(); MAX_RUNS];
            let Some(path_count) = encode_path(numerator, denominator, &mut path) else { return -1; };
            let total_depth: i64 = path[..path_count].iter().map(|run| run.count).sum();
            if !append(&mut words, &mut word_count, operation) { return -1; }
            if depth > total_depth {
                if !append(&mut words, &mut word_count, -1) { return -1; }
            } else {
                let mut prefix = [Run::default(); MAX_RUNS];
                let mut remaining = depth;
                let mut prefix_count = 0;
                for run in &path[..path_count] {
                    if remaining == 0 { break; }
                    let take = remaining.min(run.count);
                    prefix[prefix_count] = Run { direction: run.direction, count: take };
                    prefix_count += 1;
                    remaining -= take;
                }
                let Some(decoded) = decode_path(&prefix[..prefix_count]) else { return -1; };
                if !append(&mut words, &mut word_count, decoded.numerator)
                    || !append(&mut words, &mut word_count, decoded.denominator) { return -1; }
            }
        } else if operation == 4 {
            if position + 2 > length { return -1; }
            let (numerator, denominator) = (values[position], values[position + 1]);
            position += 2;
            if !valid_fraction(numerator, denominator) { return -1; }
            let mut path = [Run::default(); MAX_RUNS];
            let Some(path_count) = encode_path(numerator, denominator, &mut path) else { return -1; };
            let Some(decoded) = decode_path(&path[..path_count]) else { return -1; };
            for value in [operation, decoded.lower_num, decoded.lower_den,
                          decoded.upper_num, decoded.upper_den] {
                if !append(&mut words, &mut word_count, value) { return -1; }
            }
        } else {
            return -1;
        }
    }
    if position != length { return -1; }
    let byte_count = word_count * 8;
    if output_capacity < byte_count || output.is_null() { return -2; }
    for (index, value) in words[..word_count].iter().enumerate() {
        let bits = *value as u64;
        for byte in 0..8 {
            *output.add(index * 8 + byte) = (bits >> (byte * 8)) as u8;
        }
    }
    query_count
}
