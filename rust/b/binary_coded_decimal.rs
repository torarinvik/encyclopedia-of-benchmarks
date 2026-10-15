/// Write the prefixed four-bit-per-decimal-digit BCD representation.
#[no_mangle]
pub extern "C" fn binary_coded_decimal(value: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if !(-2_147_483_648..=2_147_483_647).contains(&value) {
        return -1;
    }
    let normalized = value.max(0) as u32;
    let mut digits = [0u8; 10];
    let mut digit_count = 0usize;
    let mut remaining = normalized;
    while remaining > 0 {
        digits[digit_count] = (remaining % 10) as u8;
        digit_count += 1;
        remaining /= 10;
    }
    if digit_count == 0 {
        digits[0] = 0;
        digit_count = 1;
    }

    let output_length = 2 + digit_count * 4;
    if output.is_null() || output_capacity < output_length {
        return -2;
    }
    unsafe {
        *output.add(0) = b'0';
        *output.add(1) = b'b';
        let mut position = 2usize;
        while digit_count > 0 {
            digit_count -= 1;
            let digit = digits[digit_count];
            for bit in (0..=3).rev() {
                *output.add(position) = b'0' + ((digit >> bit) & 1);
                position += 1;
            }
        }
    }
    output_length as i64
}
