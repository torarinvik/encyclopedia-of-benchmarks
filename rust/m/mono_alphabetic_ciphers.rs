const MAX_PARSEABLE_INPUT_LENGTH: usize = 157;
const FNV_OFFSET_BASIS: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;
const MASK_63: u64 = 0x7fffffffffffffff;

#[no_mangle]
pub unsafe extern "C" fn mono_alphabetic_ciphers(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    let operation = input[0];
    let raw_text_length = input[1];
    if (operation != 0 && operation != 1) || raw_text_length < 0 || raw_text_length > 128 { return -1; }
    let text_length = raw_text_length as usize;
    if length != 28 + text_length { return -1; }

    let mut seen = [false; 26];
    let mut inverse = [0usize; 26];
    for i in 0..26 {
        let value = input[2 + i];
        if !(65..=90).contains(&value) { return -1; }
        let index = (value - 65) as usize;
        if seen[index] { return -1; }
        seen[index] = true;
        inverse[index] = i;
    }
    let text = &input[28..28 + text_length];
    if text.iter().any(|&value| !(32..=126).contains(&value)) { return -1; }

    let mut hash = FNV_OFFSET_BASIS;
    for byte in (text_length as u64).to_le_bytes() {
        hash = (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME);
    }
    for &value in text {
        let mut mapped = value as u8;
        if (65..=90).contains(&value) || (97..=122).contains(&value) {
            let lower = (97..=122).contains(&value);
            let letter = (if lower { value - 97 } else { value - 65 }) as usize;
            let position = if operation == 0 { inverse[letter] } else { letter };
            let target = if operation == 0 { 65 + position as i64 } else { input[2 + position] } as u8;
            mapped = if lower { target + 32 } else { target };
        }
        hash = (hash ^ u64::from(mapped)).wrapping_mul(FNV_PRIME);
    }
    (hash & MASK_63) as i64
}
