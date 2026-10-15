const REQUIRED_BYTES: [usize; 7] = [0, 2, 8, 30, 112, 420, 1584];

fn walk(pairs: usize, opened: usize, closed: usize, buffer: &mut [u8; 12], output: &mut [u8], cursor: usize) -> usize {
    let position = opened + closed;
    if position == 2 * pairs {
        output[cursor..cursor + position].copy_from_slice(&buffer[..position]);
        return cursor + position;
    }
    let mut next = cursor;
    if opened < pairs {
        buffer[position] = b'(';
        next = walk(pairs, opened + 1, closed, buffer, output, next);
    }
    if closed < opened {
        buffer[position] = b')';
        next = walk(pairs, opened, closed + 1, buffer, output, next);
    }
    next
}

#[no_mangle]
pub unsafe extern "C" fn generate_parentheses(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 1 {
        return -1;
    }
    let pair_value = *input;
    if !(1..=6).contains(&pair_value) {
        return -1;
    }
    let pairs = pair_value as usize;
    let required = REQUIRED_BYTES[pairs];
    if capacity < required || output.is_null() {
        return -2;
    }
    let mut buffer = [0_u8; 12];
    let target = std::slice::from_raw_parts_mut(output, required);
    walk(pairs, 0, 0, &mut buffer, target, 0) as i64
}
