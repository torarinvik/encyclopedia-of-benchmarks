/// Truncate signed 32-bit division toward zero using doubled divisor chunks.
const INVALID_RESULT: i64 = -2_147_483_649;

#[no_mangle]
pub extern "C" fn divide_two_integers(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 2 { return INVALID_RESULT; }
    let dividend = unsafe { *values };
    let divisor = unsafe { *values.add(1) };
    if dividend < i32::MIN as i64 || dividend > i32::MAX as i64 ||
        divisor < i32::MIN as i64 || divisor > i32::MAX as i64 || divisor == 0 {
        return INVALID_RESULT;
    }

    let mut remaining = if dividend < 0 { -dividend } else { dividend };
    let divisor_magnitude = if divisor < 0 { -divisor } else { divisor };
    let mut quotient = 0_i64;
    for shift in (0..=31).rev() {
        if divisor_magnitude <= (remaining >> shift) {
            remaining -= divisor_magnitude << shift;
            quotient += 1_i64 << shift;
        }
    }

    let negative = (dividend < 0) ^ (divisor < 0);
    if negative {
        if quotient == 2_147_483_648 { return i32::MIN as i64; }
        return -quotient;
    }
    quotient.min(i32::MAX as i64)
}
