#[no_mangle]
pub unsafe extern "C" fn single_bit_manipulation_operations(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (opcode, number, position) = (values[0], values[1], values[2]);
    if !(0..=5).contains(&opcode) || number < i32::MIN as i64 || number > i32::MAX as i64 { return -1; }
    if opcode == 5 {
        if position != -1 { return -1; }
        return number & (number - 1);
    }
    if !(0..=31).contains(&position) { return -1; }
    let mask = 1i64 << position;
    match opcode {
        0 => number | mask,
        1 => number & !mask,
        2 => number ^ mask,
        3 => ((number as u64 >> position) & 1) as i64,
        4 => if number & mask != 0 { 1 } else { 0 },
        _ => -1,
    }
}
