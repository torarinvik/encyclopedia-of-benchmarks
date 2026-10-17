const MAX_PARSEABLE_INPUT_LENGTH: usize = 183;
const FNV_OFFSET_BASIS: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;
const MASK_63: u64 = 0x7fffffffffffffff;

#[no_mangle]
pub unsafe extern "C" fn mono_alphabetic_cipher(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    let operation = input[0];
    let raw_text_length = input[1];
    if (operation != 0 && operation != 1) || raw_text_length < 0 || raw_text_length > 128 { return -1; }
    let text_length = raw_text_length as usize;
    if length != 54 + text_length { return -1; }

    let mut key_seen = [false; 26];
    let mut alphabet_seen = [false; 26];
    let mut key_inverse = [0usize; 26];
    let mut alphabet_inverse = [0usize; 26];
    for i in 0..26 {
        let key_value = input[2 + i];
        let alphabet_value = input[28 + i];
        if !(65..=90).contains(&key_value) || !(65..=90).contains(&alphabet_value) { return -1; }
        let key_index = (key_value - 65) as usize;
        let alphabet_index = (alphabet_value - 65) as usize;
        if key_seen[key_index] || alphabet_seen[alphabet_index] { return -1; }
        key_seen[key_index] = true;
        alphabet_seen[alphabet_index] = true;
        key_inverse[key_index] = i;
        alphabet_inverse[alphabet_index] = i;
    }
    let text = &input[54..54 + text_length];
    let mut output_length = 0usize;
    for &value in text {
        if value != 32 && !(48..=57).contains(&value) &&
            !(65..=90).contains(&value) && !(97..=122).contains(&value) { return -1; }
        if !(48..=57).contains(&value) { output_length += 1; }
    }

    let mut hash = FNV_OFFSET_BASIS;
    for byte in (output_length as u64).to_le_bytes() {
        hash = (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME);
    }
    for &value in text {
        if (48..=57).contains(&value) { continue; }
        let mapped = if value == 32 { 32 } else {
            let lower = (97..=122).contains(&value);
            let letter = (if lower { value - 97 } else { value - 65 }) as usize;
            let position = if operation == 0 { alphabet_inverse[letter] } else { key_inverse[letter] };
            let target = if operation == 0 { input[2 + position] } else { input[28 + position] } as u8;
            if lower { target + 32 } else { target }
        };
        hash = (hash ^ u64::from(mapped))
            .wrapping_mul(FNV_PRIME);
    }
    (hash & MASK_63) as i64
}
