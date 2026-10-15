/// Check for a permutation of one lowercase ASCII string inside another.
const MAX_STRING_LENGTH: usize = 1024;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_STRING_LENGTH;

fn adjust_count(differences: &mut [i64; 26], nonzero: &mut i64, letter: usize, amount: i64) {
    if differences[letter] == 0 { *nonzero += 1; }
    differences[letter] += amount;
    if differences[letter] == 0 { *nonzero -= 1; }
}

#[no_mangle]
pub extern "C" fn permutation_in_string(input: *const i64, length: usize) -> i64 {
    if length < 2 || length > MAX_INPUT_LENGTH || input.is_null() { return -1; }
    let first_length_value = unsafe { *input };
    let second_length_value = unsafe { *input.add(1) };
    if first_length_value < 0 || first_length_value > MAX_STRING_LENGTH as i64 ||
        second_length_value < 0 || second_length_value > MAX_STRING_LENGTH as i64 { return -1; }
    let first_length = first_length_value as usize;
    let second_length = second_length_value as usize;
    if length != 2 + first_length + second_length { return -1; }
    for index in 2..length {
        let value = unsafe { *input.add(index) };
        if !(97..=122).contains(&value) { return -1; }
    }
    if first_length > second_length { return 0; }

    let mut differences = [0_i64; 26];
    let mut nonzero = 0_i64;
    for index in 0..first_length {
        let pattern = unsafe { *input.add(2 + index) };
        let window = unsafe { *input.add(2 + first_length + index) };
        adjust_count(&mut differences, &mut nonzero, (pattern - 97) as usize, 1);
        adjust_count(&mut differences, &mut nonzero, (window - 97) as usize, -1);
    }
    if nonzero == 0 { return 1; }
    for start in 0..second_length - first_length {
        let outgoing = unsafe { *input.add(2 + first_length + start) };
        let incoming = unsafe { *input.add(2 + first_length + start + first_length) };
        adjust_count(&mut differences, &mut nonzero, (outgoing - 97) as usize, 1);
        adjust_count(&mut differences, &mut nonzero, (incoming - 97) as usize, -1);
        if nonzero == 0 { return 1; }
    }
    0
}
