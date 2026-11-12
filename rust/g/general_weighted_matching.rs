use std::slice;

const MAX_N: usize = 16;
const MAX_STATES: usize = 1 << MAX_N;
const MAX_OUTPUT_WORDS: usize = 2 + MAX_N;
const MAX_INPUT_VALUES: usize = 2 + 3 * (MAX_N * (MAX_N - 1) / 2) + 1;
const MAX_WEIGHT: i64 = 1_000_000;

fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn general_weighted_matching(
    input_ptr: *const i64,
    length: usize,
    output_ptr: *mut u8,
    capacity: usize,
) -> i64 {
    if input_ptr.is_null() || length < 2 || length > MAX_INPUT_VALUES { return -1; }
    let input = slice::from_raw_parts(input_ptr, length);
    let (nv, mv) = (input[0], input[1]);
    if !(1..=MAX_N as i64).contains(&nv) || mv < 0 || mv > nv * (nv - 1) / 2 { return -1; }
    let (n, m) = (nv as usize, mv as usize);
    if length != 2 + 3 * m { return -1; }

    let mut weights = [[0i64; MAX_N]; MAX_N];
    let mut present = [[false; MAX_N]; MAX_N];
    let mut cursor = 2;
    for _ in 0..m {
        let (u_value, v_value, edge_weight) = (input[cursor], input[cursor + 1], input[cursor + 2]);
        cursor += 3;
        if u_value < 0 || u_value >= nv || v_value < 0 || v_value >= nv ||
            u_value == v_value || !(1..=MAX_WEIGHT).contains(&edge_weight) { return -1; }
        let (u, v) = (u_value as usize, v_value as usize);
        if present[u][v] { return -1; }
        present[u][v] = true;
        present[v][u] = true;
        weights[u][v] = edge_weight;
        weights[v][u] = edge_weight;
    }

    let mut dp = [0i64; MAX_STATES];
    let state_count = 1usize << n;
    for mask in 1..state_count {
        let bit = mask & mask.wrapping_neg();
        let vertex = bit.trailing_zeros() as usize;
        let remainder = mask ^ bit;
        dp[mask] = dp[remainder];
        for partner in vertex + 1..n {
            let partner_bit = 1usize << partner;
            if remainder & partner_bit == 0 || !present[vertex][partner] { continue; }
            let candidate = weights[vertex][partner] + dp[remainder ^ partner_bit];
            if candidate > dp[mask] { dp[mask] = candidate; }
        }
    }

    let mut words = [0i64; MAX_OUTPUT_WORDS];
    let mut pair_count = 0usize;
    let mut mask = state_count - 1;
    while mask != 0 {
        let bit = mask & mask.wrapping_neg();
        let vertex = bit.trailing_zeros() as usize;
        let remainder = mask ^ bit;
        if dp[mask] == dp[remainder] {
            mask = remainder;
            continue;
        }
        let mut selected = None;
        for partner in vertex + 1..n {
            let partner_bit = 1usize << partner;
            if remainder & partner_bit != 0 && present[vertex][partner] &&
                weights[vertex][partner] + dp[remainder ^ partner_bit] == dp[mask] {
                selected = Some(partner);
                break;
            }
        }
        let partner = match selected { Some(value) => value, None => return -1 };
        words[2 + 2 * pair_count] = vertex as i64;
        words[3 + 2 * pair_count] = partner as i64;
        pair_count += 1;
        mask = remainder ^ (1usize << partner);
    }

    words[0] = pair_count as i64;
    words[1] = dp[state_count - 1];
    let output_bytes = 8 * (2 + 2 * pair_count);
    if output_ptr.is_null() || capacity < output_bytes { return -2; }
    let output = slice::from_raw_parts_mut(output_ptr, output_bytes);
    for word in 0..2 + 2 * pair_count {
        store_i64_le(output, 8 * word, words[word]);
    }
    output_bytes as i64
}
