const MAX_N: usize = 4096;
const MAX_WORDS: usize = (MAX_N + 63) / 64;
const MAX_QUERIES: usize = 512;
const MAX_INPUT_LENGTH: usize = 2 + MAX_WORDS + 2 * MAX_QUERIES;
const MAX_OUTPUT_BYTES: usize = MAX_QUERIES * 8;

fn find_next(words: &[u64; MAX_WORDS], word_count: usize, n: usize, key: usize) -> i64 {
    let first_word = key / 64;
    for word in first_word..word_count {
        let first_bit = if word == first_word { key % 64 } else { 0 };
        let mut candidates = words[word];
        if first_bit != 0 { candidates &= u64::MAX << first_bit; }
        if candidates == 0 { continue; }
        let end_bit = if (word + 1) * 64 < n { 64 } else { n - word * 64 };
        for bit in first_bit..end_bit {
            if (candidates >> bit) & 1 != 0 { return (word * 64 + bit) as i64; }
        }
    }
    -1
}

fn find_previous(words: &[u64; MAX_WORDS], n: usize, key: usize) -> i64 {
    let first_word = key / 64;
    for index in (0..=first_word).rev() {
        let end_bit = if index == first_word { key % 64 + 1 }
                      else if (index + 1) * 64 > n { n - index * 64 }
                      else { 64 };
        let mask = if end_bit == 64 { u64::MAX } else { (1u64 << end_bit) - 1 };
        let candidates = words[index] & mask;
        if candidates == 0 { continue; }
        for bit in (0..end_bit).rev() {
            if (candidates >> bit) & 1 != 0 { return (index * 64 + bit) as i64; }
        }
    }
    -1
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

/// Packed-bitset implementation of dynamic membership and neighbor queries.
#[no_mangle]
pub unsafe extern "C" fn predecessor_problem(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    let query_value = values[1];
    if n_value < 1 || n_value > MAX_N as i64 || query_value < 0 || query_value > MAX_QUERIES as i64 { return -1; }
    let n = n_value as usize;
    let queries = query_value as usize;
    let word_count = (n + 63) / 64;
    let operation_offset = 2 + word_count;
    if length != operation_offset + 2 * queries { return -1; }
    let mut words = [0u64; MAX_WORDS];
    for word in 0..word_count { words[word] = values[2 + word] as u64; }
    let tail_bits = n % 64;
    if tail_bits != 0 && words[word_count - 1] >> tail_bits != 0 { return -1; }
    for query in 0..queries {
        let operation = values[operation_offset + 2 * query];
        let key = values[operation_offset + 2 * query + 1];
        if !(0..=4).contains(&operation) || key < 0 || key >= n_value { return -1; }
    }
    let mut answers = [0i64; MAX_QUERIES];
    let mut answer_count = 0;
    for query in 0..queries {
        let operation = values[operation_offset + 2 * query];
        let key = values[operation_offset + 2 * query + 1] as usize;
        let word = key / 64;
        let mask = 1u64 << (key % 64);
        match operation {
            0 => words[word] |= mask,
            1 => words[word] &= !mask,
            2 => { answers[answer_count] = i64::from(words[word] & mask != 0); answer_count += 1; }
            3 => { answers[answer_count] = find_next(&words, word_count, n, key); answer_count += 1; }
            _ => { answers[answer_count] = find_previous(&words, n, key); answer_count += 1; }
        }
    }
    let output_bytes = answer_count * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    for index in 0..answer_count { store_i64_le(staged.as_mut_ptr(), index * 8, answers[index]); }
    for (index, byte) in staged[..output_bytes].iter().enumerate() { *output.add(index) = *byte; }
    output_bytes as i64
}
