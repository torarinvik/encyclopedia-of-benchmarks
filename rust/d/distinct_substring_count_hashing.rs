const MAX_TEXT: i64 = 64;
const MAX_INPUT_LENGTH: usize = 66;
const MODULUS: i64 = 1_000_000_007;

fn execute(input: &[i64]) -> Result<i64, ()> {
    if input.is_empty() || input.len() > MAX_INPUT_LENGTH { return Err(()); }
    let n_value = input[0];
    if n_value < 0 || n_value > MAX_TEXT || input.len() != n_value as usize + 1 { return Err(()); }
    let n = n_value as usize;
    let symbols = &input[1..];
    if symbols.iter().any(|&symbol| !(0..=255).contains(&symbol)) { return Err(()); }

    let mut prefix = [0i64; 65];
    let mut powers = [0i64; 65];
    powers[0] = 1;
    for i in 0..n {
        prefix[i + 1] = (prefix[i] * 257 + symbols[i] + 1) % MODULUS;
        powers[i + 1] = powers[i] * 257 % MODULUS;
    }
    let mut group_hash = [-1i64; 64];
    let mut group_head = [-1i64; 64];
    let mut representative_start = [0i64; 64];
    let mut representative_next = [0i64; 64];
    let mut distinct = 0i64;
    for width in 1..=n {
        group_hash.fill(-1);
        group_head.fill(-1);
        let mut representative_count = 0usize;
        for start in 0..=n - width {
            let end = start + width;
            let mut fingerprint = (prefix[end] - prefix[start] * powers[width] % MODULUS) % MODULUS;
            if fingerprint < 0 { fingerprint += MODULUS; }
            let mut slot = (fingerprint % 64) as usize;
            while group_hash[slot] != -1 && group_hash[slot] != fingerprint { slot = (slot + 1) % 64; }
            if group_hash[slot] == -1 { group_hash[slot] = fingerprint; }

            let mut duplicate = false;
            let mut prior = group_head[slot];
            while prior >= 0 {
                let old_start = representative_start[prior as usize] as usize;
                if symbols[start..end] == symbols[old_start..old_start + width] {
                    duplicate = true;
                    break;
                }
                prior = representative_next[prior as usize];
            }
            if !duplicate {
                representative_start[representative_count] = start as i64;
                representative_next[representative_count] = group_head[slot];
                group_head[slot] = representative_count as i64;
                representative_count += 1;
                distinct += 1;
            }
        }
    }
    Ok(distinct)
}

#[no_mangle]
pub unsafe extern "C" fn distinct_substring_count_hashing(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 || length > MAX_INPUT_LENGTH { return -1; }
    execute(std::slice::from_raw_parts(input, length)).unwrap_or(-1)
}
