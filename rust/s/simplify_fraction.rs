const MAX_ABS_COMPONENT: i64 = 1_000_000;

#[no_mangle]
pub unsafe extern "C" fn simplify_fraction(input: *const i64, input_length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || input_length != 2 { return -1; }
    let numerator = *input;
    let denominator = *input.add(1);
    if numerator < -MAX_ABS_COMPONENT || numerator > MAX_ABS_COMPONENT ||
        denominator < -MAX_ABS_COMPONENT || denominator > MAX_ABS_COMPONENT || denominator == 0 { return -1; }
    let mut a = numerator.unsigned_abs();
    let mut b = denominator.unsigned_abs();
    while b != 0 { let remainder = a % b; a = b; b = remainder; }
    let divisor = a as i64;
    let reduced_numerator = numerator / divisor;
    let reduced_denominator = denominator / divisor;
    let mut staged = [0u8; 16];
    staged[..8].copy_from_slice(&reduced_numerator.to_le_bytes());
    staged[8..].copy_from_slice(&reduced_denominator.to_le_bytes());
    if output.is_null() || capacity < staged.len() { return -2; }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, staged.len());
    staged.len() as i64
}
