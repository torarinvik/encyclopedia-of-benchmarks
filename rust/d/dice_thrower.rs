const MAX_TARGET: usize = 8;

fn required_bytes(remaining: usize, depth: usize) -> usize {
    if remaining == 0 {
        return depth + 1;
    }
    let mut total = 0;
    for face in 1..=remaining.min(6) {
        total += required_bytes(remaining - face, depth + 1);
    }
    total
}

unsafe fn emit_combinations(
    remaining: usize,
    depth: usize,
    digits: &mut [u8; MAX_TARGET],
    output: *mut u8,
    position: &mut usize,
) {
    if remaining == 0 {
        for &digit in &digits[..depth] {
            *output.add(*position) = digit;
            *position += 1;
        }
        *output.add(*position) = b'\n';
        *position += 1;
        return;
    }
    for face in 1..=remaining.min(6) {
        digits[depth] = b'0' + face as u8;
        emit_combinations(remaining - face, depth + 1, digits, output, position);
    }
}

#[no_mangle]
pub unsafe extern "C" fn dice_thrower(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length != 1 || *values < 0 || *values > MAX_TARGET as i64 {
        return -1;
    }
    let target = *values as usize;
    let needed = required_bytes(target, 0);
    if output_capacity < needed || output.is_null() {
        return -2;
    }
    let mut digits = [0u8; MAX_TARGET];
    let mut position = 0;
    emit_combinations(target, 0, &mut digits, output, &mut position);
    position as i64
}
