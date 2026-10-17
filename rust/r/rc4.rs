const MAX_KEY_LENGTH: usize = 256;
const MAX_PLAINTEXT_LENGTH: usize = 256;
const MAX_INPUT_VALUES: usize = 515;

#[no_mangle]
pub unsafe extern "C" fn rc4(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_VALUES {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let key_length_value = values[0];
    let plaintext_length_value = values[1];
    if !(1..=MAX_KEY_LENGTH as i64).contains(&key_length_value)
        || !(0..=MAX_PLAINTEXT_LENGTH as i64).contains(&plaintext_length_value)
    {
        return -1;
    }
    let key_length = key_length_value as usize;
    let plaintext_length = plaintext_length_value as usize;
    if length != 2 + key_length + plaintext_length {
        return -1;
    }
    for &byte in &values[2..] {
        if !(0..=255).contains(&byte) {
            return -1;
        }
    }
    if plaintext_length == 0 {
        return 0;
    }
    if output.is_null() || capacity < plaintext_length {
        return -2;
    }

    let mut state = [0u8; 256];
    for (index, value) in state.iter_mut().enumerate() {
        *value = index as u8;
    }
    let mut j = 0usize;
    for index in 0..256 {
        j = (j + state[index] as usize + values[2 + index % key_length] as usize) & 255;
        state.swap(index, j);
    }

    let mut i = 0usize;
    j = 0;
    for offset in 0..plaintext_length {
        i = (i + 1) & 255;
        j = (j + state[i] as usize) & 255;
        state.swap(i, j);
        let stream_index = (state[i] as usize + state[j] as usize) & 255;
        let plaintext = values[2 + key_length + offset] as u8;
        *output.add(offset) = plaintext ^ state[stream_index];
    }
    plaintext_length as i64
}
