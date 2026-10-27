const MAX_TEXT_LENGTH: usize = 16;
const MAX_INPUT_LENGTH: usize = 18;
const MAX_OUTPUT_BYTES: usize = 128;

fn symbol_at(symbols: &[i64], position: usize) -> i64 {
    if position < symbols.len() { symbols[position] } else { 0 }
}

fn sample_rank(ranks: &[i64], position: usize) -> i64 {
    if position < ranks.len() { ranks[position] } else { -1 }
}

fn triple_compare(symbols: &[i64], left: usize, right: usize) -> i32 {
    for offset in 0..3 {
        let a = symbol_at(symbols, left + offset);
        let b = symbol_at(symbols, right + offset);
        if a != b { return if a < b { -1 } else { 1 }; }
    }
    0
}

fn suffix_compare(symbols: &[i64], mut left: usize, mut right: usize) -> i32 {
    while left < symbols.len() && right < symbols.len() {
        if symbols[left] != symbols[right] { return if symbols[left] < symbols[right] { -1 } else { 1 }; }
        left += 1;
        right += 1;
    }
    if left == symbols.len() && right == symbols.len() { 0 }
    else if left == symbols.len() { -1 } else { 1 }
}

fn zero_pair_compare(symbols: &[i64], ranks: &[i64], left: usize, right: usize) -> i32 {
    let a = symbol_at(symbols, left);
    let b = symbol_at(symbols, right);
    if a != b { return if a < b { -1 } else { 1 }; }
    let a = sample_rank(ranks, left + 1);
    let b = sample_rank(ranks, right + 1);
    if a != b { if a < b { -1 } else { 1 } } else { 0 }
}

fn merge_compare(symbols: &[i64], ranks: &[i64], zero: usize, sample: usize) -> i32 {
    let a = symbol_at(symbols, zero);
    let b = symbol_at(symbols, sample);
    if a != b { return if a < b { -1 } else { 1 }; }
    if sample % 3 == 1 {
        let a = sample_rank(ranks, zero + 1);
        let b = sample_rank(ranks, sample + 1);
        if a != b { return if a < b { -1 } else { 1 }; }
    } else {
        let a = symbol_at(symbols, zero + 1);
        let b = symbol_at(symbols, sample + 1);
        if a != b { return if a < b { -1 } else { 1 }; }
        let a = sample_rank(ranks, zero + 2);
        let b = sample_rank(ranks, sample + 2);
        if a != b { return if a < b { -1 } else { 1 }; }
    }
    0
}

fn dc3(symbols: &[i64], suffixes: &mut [usize]) {
    let n = symbols.len();
    if n == 0 { return; }
    if n <= 3 {
        for i in 0..n { suffixes[i] = i; }
        for i in 1..n {
            let key = suffixes[i];
            let mut position = i;
            while position > 0 && suffix_compare(symbols, key, suffixes[position - 1]) < 0 {
                suffixes[position] = suffixes[position - 1];
                position -= 1;
            }
            suffixes[position] = key;
        }
        return;
    }

    let mut sample_positions = [0usize; MAX_TEXT_LENGTH];
    let mut sample_count = 0;
    for i in 1..n {
        if i % 3 != 0 { sample_positions[sample_count] = i; sample_count += 1; }
    }
    for i in 1..sample_count {
        let key = sample_positions[i];
        let mut position = i;
        while position > 0 && triple_compare(symbols, key, sample_positions[position - 1]) < 0 {
            sample_positions[position] = sample_positions[position - 1];
            position -= 1;
        }
        sample_positions[position] = key;
    }

    let mut triple_ranks = [0i64; MAX_TEXT_LENGTH];
    let mut next_rank = 0i64;
    for i in 0..sample_count {
        if i == 0 || triple_compare(symbols, sample_positions[i - 1], sample_positions[i]) != 0 { next_rank += 1; }
        triple_ranks[sample_positions[i]] = next_rank;
    }

    let mut group_one_count = 0;
    for i in (1..n).step_by(3) { group_one_count += 1; }
    let mut reduced = [0i64; MAX_TEXT_LENGTH];
    let mut reduced_length = 0;
    for i in (1..n).step_by(3) { reduced[reduced_length] = triple_ranks[i]; reduced_length += 1; }
    reduced[reduced_length] = 0;
    reduced_length += 1;
    for i in (2..n).step_by(3) { reduced[reduced_length] = triple_ranks[i]; reduced_length += 1; }
    let mut reduced_order = [0usize; MAX_TEXT_LENGTH];
    dc3(&reduced[..reduced_length], &mut reduced_order[..reduced_length]);

    let mut sample_order = [0usize; MAX_TEXT_LENGTH];
    let mut ranks = [-1i64; MAX_TEXT_LENGTH];
    let mut sample_order_count = 0;
    for i in 0..reduced_length {
        let reduced_position = reduced_order[i];
        if reduced_position == group_one_count { continue; }
        let source_position = if reduced_position < group_one_count {
            1 + 3 * reduced_position
        } else {
            2 + 3 * (reduced_position - group_one_count - 1)
        };
        sample_order[sample_order_count] = source_position;
        ranks[source_position] = sample_order_count as i64;
        sample_order_count += 1;
    }

    let mut zero_positions = [0usize; MAX_TEXT_LENGTH];
    let mut zero_count = 0;
    for i in (0..n).step_by(3) { zero_positions[zero_count] = i; zero_count += 1; }
    for i in 1..zero_count {
        let key = zero_positions[i];
        let mut position = i;
        while position > 0 && zero_pair_compare(symbols, &ranks[..n], key, zero_positions[position - 1]) < 0 {
            zero_positions[position] = zero_positions[position - 1];
            position -= 1;
        }
        zero_positions[position] = key;
    }

    let (mut zi, mut si, mut oi) = (0, 0, 0);
    while zi < zero_count && si < sample_order_count {
        let zero = zero_positions[zi];
        let sample = sample_order[si];
        if merge_compare(symbols, &ranks[..n], zero, sample) < 0 {
            suffixes[oi] = zero_positions[zi]; zi += 1;
        } else {
            suffixes[oi] = sample_order[si]; si += 1;
        }
        oi += 1;
    }
    while zi < zero_count { suffixes[oi] = zero_positions[zi]; zi += 1; oi += 1; }
    while si < sample_order_count { suffixes[oi] = sample_order[si]; si += 1; oi += 1; }
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(offset), 8);
}

#[no_mangle]
pub unsafe extern "C" fn suffix_array_dc3(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let count_value = input[0];
    if count_value < 0 || count_value > MAX_TEXT_LENGTH as i64 { return -1; }
    let count = count_value as usize;
    if length != count + 1 || input[1..].iter().any(|value| !(0..=255).contains(value)) { return -1; }
    let output_bytes = count * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    if count == 0 { return 0; }
    let mut symbols = [0i64; MAX_TEXT_LENGTH];
    for i in 0..count { symbols[i] = input[i + 1] + 1; }
    let mut suffixes = [0usize; MAX_TEXT_LENGTH];
    dc3(&symbols[..count], &mut suffixes[..count]);
    for i in 0..count { store_i64_le(output, i * 8, suffixes[i] as i64); }
    output_bytes as i64
}
