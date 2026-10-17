const MAX_TEXT_LENGTH: usize = 256;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 285;
const FNV_OFFSET_BASIS: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;
const MASK_63: u64 = 0x7fffffffffffffff;

#[no_mangle]
pub unsafe extern "C" fn mono_alphabetic(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    let operation = input[0];
    let raw_text_length = input[1];
    if (operation != 0 && operation != 1) || raw_text_length < 1 || raw_text_length > MAX_TEXT_LENGTH as i64 { return -1; }
    let text_length = raw_text_length as usize;
    if length != 28 + text_length { return -1; }

    let mut seen = [false; 26];
    let mut inverse = [0u8; 26];
    for i in 0..26 {
        let value = input[2 + i];
        if !(65..=90).contains(&value) { return -1; }
        let index = (value - 65) as usize;
        if seen[index] { return -1; }
        seen[index] = true;
        inverse[index] = i as u8;
    }
    if input[28..28 + text_length].iter().any(|&value| !(65..=90).contains(&value)) { return -1; }

    let mut hash = FNV_OFFSET_BASIS;
    for byte in (text_length as u64).to_le_bytes() {
        hash = (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME);
    }
    for &value in &input[28..28 + text_length] {
        let index = (value - 65) as usize;
        let mapped = if operation == 0 { input[2 + index] as u8 } else { 65 + inverse[index] };
        hash = (hash ^ u64::from(mapped)).wrapping_mul(FNV_PRIME);
    }
    (hash & MASK_63) as i64
}
