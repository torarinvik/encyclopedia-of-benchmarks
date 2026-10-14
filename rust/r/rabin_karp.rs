/// Test ASCII pattern presence with a Rabin-Karp rolling hash.
#[no_mangle]
pub extern "C" fn rabin_karp(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > 512 {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let text_length = values[0];
    let pattern_length = values[1];
    if !(0..=255).contains(&text_length)
        || !(0..=255).contains(&pattern_length)
        || length != 2 + text_length as usize + pattern_length as usize
    {
        return -1;
    }
    let text_length = text_length as usize;
    let pattern_length = pattern_length as usize;
    let text = &values[2..2 + text_length];
    let pattern = &values[2 + text_length..];
    if text.iter().chain(pattern.iter()).any(|&value| !(0..=127).contains(&value)) {
        return -1;
    }
    if pattern_length == 0 {
        return 1;
    }
    if pattern_length > text_length {
        return 0;
    }

    const BASE: i64 = 256;
    const MODULUS: i64 = 1_000_003;
    let mut pattern_hash = 0;
    let mut rolling_hash = 0;
    let mut high_power = 1;
    for index in 0..pattern_length {
        pattern_hash = (pattern_hash * BASE + pattern[index]) % MODULUS;
        rolling_hash = (rolling_hash * BASE + text[index]) % MODULUS;
        if index + 1 < pattern_length {
            high_power = (high_power * BASE) % MODULUS;
        }
    }
    let last_start = text_length - pattern_length;
    for start in 0..=last_start {
        if rolling_hash == pattern_hash && text[start..start + pattern_length] == *pattern {
            return 1;
        }
        if start < last_start {
            let removed = (text[start] * high_power) % MODULUS;
            rolling_hash = (rolling_hash - removed) % MODULUS;
            if rolling_hash < 0 {
                rolling_hash += MODULUS;
            }
            rolling_hash = (rolling_hash * BASE + text[start + pattern_length]) % MODULUS;
        }
    }
    0
}
