const MAX_MESSAGE_LENGTH: usize = 64;
const KEY_COUNT: usize = 26;

#[no_mangle]
pub unsafe extern "C" fn brute_force_caesar_cipher(input: *const i64, length: usize,
                                                     output: *mut u8, capacity: usize) -> i64 {
    if length > MAX_MESSAGE_LENGTH || (length > 0 && input.is_null()) { return -1; }
    for i in 0..length {
        let value = *input.add(i);
        if !(0..=127).contains(&value) { return -1; }
    }
    let needed = length * KEY_COUNT + (KEY_COUNT - 1);
    if output.is_null() || capacity < needed { return -2; }
    let mut position = 0usize;
    for key in 0..KEY_COUNT {
        for i in 0..length {
            let value = *input.add(i);
            let mapped = if (65..=90).contains(&value) {
                65 + (value - 65 + 26 - key as i64) % 26
            } else { value };
            output.add(position).write(mapped as u8);
            position += 1;
        }
        if key + 1 < KEY_COUNT {
            output.add(position).write(b'\n');
            position += 1;
        }
    }
    KEY_COUNT as i64
}
