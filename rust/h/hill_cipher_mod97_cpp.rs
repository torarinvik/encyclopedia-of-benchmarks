const ALPHABET: [u8; 97] = [65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 126, 33, 64, 35, 36, 37, 94, 38, 42, 40, 41, 95, 43, 96, 45, 61, 91, 93, 123, 125, 124, 59, 39, 34, 58, 44, 46, 47, 60, 62, 63, 92, 13, 10, 32];
const ENCRYPT_KEY: [i64; 4] = [2, 5, 1, 6];
const DECRYPT_KEY: [i64; 4] = [84, 27, 83, 28];

fn alphabet_index(value: i64) -> Option<usize> {
    ALPHABET.iter().position(|&ch| i64::from(ch) == value)
}

#[no_mangle]
pub unsafe extern "C" fn hill_cipher_mod97_cpp(values: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || !(3..=258).contains(&length) { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let operation = input[0];
    let raw_length = input[1];
    if (operation != 0 && operation != 1) || !(1..=256).contains(&raw_length) || length != raw_length as usize + 2 { return -1; }
    let text_length = raw_length as usize;
    let mut indices = [0u8; 256];
    for index in 0..text_length {
        match alphabet_index(input[index + 2]) { Some(mapped) => indices[index] = mapped as u8, None => return -1 }
    }
    let output_length = text_length + text_length % 2;
    if output.is_null() || capacity < output_length { return -2; }
    let key = if operation == 0 { &ENCRYPT_KEY } else { &DECRYPT_KEY };
    let result = std::slice::from_raw_parts_mut(output, capacity);
    for offset in (0..output_length).step_by(2) {
        let first = i64::from(indices[offset]);
        let second = if offset + 1 < text_length { i64::from(indices[offset + 1]) } else { 0 };
        let row0 = ((key[0] * first + key[1] * second) % 97) as usize;
        let row1 = ((key[2] * first + key[3] * second) % 97) as usize;
        result[offset] = ALPHABET[row0];
        result[offset + 1] = ALPHABET[row1];
    }
    output_length as i64
}
