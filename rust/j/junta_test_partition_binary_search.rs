const MAX_N: usize = 8;
const ROUNDS: usize = 24;
const MAX_OUTPUT_WORDS: usize = 7;

fn function_value(table: &[u64; 4], point: u32) -> i64 {
    ((table[(point / 64) as usize] >> (point % 64)) & 1) as i64
}

unsafe fn put_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn junta_test_partition_binary_search(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > 40 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    let groups_value = values[1];
    let table_words_value = values[2];
    if n_value < 1 || n_value > MAX_N as i64 || groups_value < 1 || groups_value > n_value { return -1; }
    let n = n_value as usize;
    let group_count = groups_value as usize;
    let domain = 1usize << n;
    let table_words = (domain + 63) / 64;
    if table_words_value != table_words as i64 { return -1; }
    let table_at = 3usize;
    let labels_at = table_at + table_words;
    let tape_at = labels_at + n;
    if length != tape_at + ROUNDS { return -1; }

    let mut table = [0u64; 4];
    for word in 0..table_words { table[word] = values[table_at + word] as u64; }
    let tail_bits = domain % 64;
    if tail_bits != 0 && table[table_words - 1] >> tail_bits != 0 { return -1; }

    let mut group_masks = [0u32; 8];
    let mut groups_seen = 0u32;
    for coordinate in 0..n {
        let group = values[labels_at + coordinate];
        if group < 0 || group >= groups_value { return -1; }
        group_masks[group as usize] |= 1u32 << coordinate;
        groups_seen |= 1u32 << (group as u32);
    }
    if groups_seen != (1u32 << group_count) - 1 { return -1; }
    let pair_limit = 1u64 << (2 * n);
    for round in 0..ROUNDS {
        let pair = values[tape_at + round];
        if pair < 0 || pair as u64 >= pair_limit { return -1; }
    }

    let mut output_words = [0i64; MAX_OUTPUT_WORDS];
    let mut event_rounds = [0i64; 2];
    let mut event_groups = [0i64; 2];
    let mut found = 0usize;
    let mut query_count = 0usize;
    let all_coordinates = (1u32 << n) - 1;
    let mut active = all_coordinates;
    for round in 0..ROUNDS {
        let packed = values[tape_at + round] as u64;
        let x = (packed & all_coordinates as u64) as u32;
        let y = ((packed >> n) & all_coordinates as u64) as u32;
        let hybrid = (x & !active) | (y & active);
        let left_value = function_value(&table, x);
        let right_value = function_value(&table, hybrid);
        query_count += 2;
        if left_value == right_value { continue; }

        let mut candidates = [0usize; 8];
        let mut candidate_count = 0usize;
        for group in 0..group_count {
            if group_masks[group] & active != 0 {
                candidates[candidate_count] = group;
                candidate_count += 1;
            }
        }
        let mut left_endpoint = x;
        let mut right_endpoint = hybrid;
        let mut endpoint_value = left_value;
        while candidate_count > 1 {
            let cut = candidate_count / 2;
            let mut low_mask = 0u32;
            for i in 0..cut { low_mask |= group_masks[candidates[i]]; }
            let probe = (left_endpoint & !low_mask) | (right_endpoint & low_mask);
            let probe_value = function_value(&table, probe);
            query_count += 1;
            if probe_value != endpoint_value {
                right_endpoint = probe;
                candidate_count = cut;
            } else {
                left_endpoint = probe;
                endpoint_value = probe_value;
                for i in cut..candidate_count { candidates[i - cut] = candidates[i]; }
                candidate_count -= cut;
            }
        }
        let selected = candidates[0];
        active &= !group_masks[selected];
        event_rounds[found] = round as i64;
        event_groups[found] = selected as i64;
        found += 1;
        if found > 1 { break; }
    }

    output_words[0] = if found > 1 { 1 } else { 0 };
    output_words[1] = found as i64;
    output_words[2] = query_count as i64;
    for i in 0..found {
        output_words[3 + 2 * i] = event_rounds[i];
        output_words[4 + 2 * i] = event_groups[i];
    }
    let word_count = 3 + 2 * found;
    let byte_count = word_count * 8;
    if output.is_null() || capacity < byte_count { return -2; }
    for i in 0..word_count { put_i64_le(output, i * 8, output_words[i]); }
    byte_count as i64
}
