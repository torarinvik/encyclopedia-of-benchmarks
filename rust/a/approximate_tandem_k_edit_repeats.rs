const MAX_TEXT: usize = 12;
const MAX_INPUT: usize = 14;
const MAX_OUTPUT: usize = 1592;

fn edit_distance(input: &[i64], a: usize, a_length: usize, b: usize, b_length: usize) -> usize {
    let mut row = [0usize; MAX_TEXT + 1];
    for j in 0..=b_length { row[j] = j; }
    for i in 1..=a_length {
        let mut diagonal = row[0];
        row[0] = i;
        for j in 1..=b_length {
            let above = row[j];
            let deletion = above + 1;
            let insertion = row[j - 1] + 1;
            let substitution = diagonal + (input[2 + a + i - 1] != input[2 + b + j - 1]) as usize;
            row[j] = deletion.min(insertion).min(substitution);
            diagonal = above;
        }
    }
    row[b_length]
}

fn minimum_edit_cost(input: &[i64], start: usize, factor_length: usize) -> usize {
    let mut best = 1000usize;
    let mut piece_starts = [0usize; MAX_TEXT];
    let mut piece_lengths = [0usize; MAX_TEXT];
    for prefix in 0..=factor_length {
        for suffix in 0..=factor_length - prefix {
            let middle = factor_length - prefix - suffix;
            if middle < 2 { continue; }
            let end_mask = 1usize << (middle - 1);
            for mask in 1..end_mask {
                let mut segments = 0usize;
                let mut previous = 0usize;
                for cut in 1..middle {
                    if mask & (1usize << (cut - 1)) != 0 {
                        piece_starts[segments] = start + prefix + previous;
                        piece_lengths[segments] = cut - previous;
                        segments += 1;
                        previous = cut;
                    }
                }
                piece_starts[segments] = start + prefix + previous;
                piece_lengths[segments] = middle - previous;
                segments += 1;
                let mut left = 1000usize;
                for fragment in 0..=piece_lengths[0] {
                    left = left.min(edit_distance(input, start, prefix,
                        piece_starts[0] + piece_lengths[0] - fragment, fragment));
                }
                let last = segments - 1;
                let mut right = 1000usize;
                for fragment in 0..=piece_lengths[last] {
                    right = right.min(edit_distance(input, piece_starts[last], fragment,
                        start + factor_length - suffix, suffix));
                }
                let mut internal = 0usize;
                for i in 0..last {
                    internal += edit_distance(input, piece_starts[i], piece_lengths[i],
                                              piece_starts[i + 1], piece_lengths[i + 1]);
                }
                best = best.min(left + internal + right);
            }
        }
    }
    best
}

fn count_records(input: &[i64], n: usize, budget: usize) -> usize {
    let mut count = 0;
    for start in 0..n {
        for factor_length in 2..=n - start {
            count += (minimum_edit_cost(input, start, factor_length) <= budget) as usize;
        }
    }
    count
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn approximate_tandem_k_edit_repeats(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    let n0 = words[0];
    let budget0 = words[1];
    if n0 < 2 || n0 > MAX_TEXT as i64 || budget0 < 0 || budget0 > 4 || length != n0 as usize + 2 { return -1; }
    let n = n0 as usize;
    let budget = budget0 as usize;
    if words[2..].iter().any(|&symbol| !(0..=3).contains(&symbol)) { return -1; }
    let count = count_records(words, n, budget);
    let bytes = 8 * (1 + 3 * count);
    if bytes > MAX_OUTPUT { return -1; }
    if output.is_null() || capacity < bytes { return -2; }
    store_i64_le(output, 0, count as i64);
    let mut record = 0usize;
    for start in 0..n {
        for factor_length in 2..=n - start {
            let cost = minimum_edit_cost(words, start, factor_length);
            if cost <= budget {
                let offset = 8 * (1 + 3 * record);
                store_i64_le(output, offset, start as i64);
                store_i64_le(output, offset + 8, factor_length as i64);
                store_i64_le(output, offset + 16, cost as i64);
                record += 1;
            }
        }
    }
    bytes as i64
}
