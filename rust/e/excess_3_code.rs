#[no_mangle]
pub unsafe extern "C" fn excess_3_code(value: i64, output: *mut u8, output_capacity: usize) -> i64 {
    let mut number = if value < 0 { 0_u64 } else { value as u64 };
    let mut digits = [0_u8; 19];
    let mut count = 0;
    while number > 0 {
        digits[count] = (number % 10) as u8;
        count += 1;
        number /= 10;
    }
    if count == 0 {
        digits[0] = 0;
        count = 1;
    }
    let output_length = 2 + 4 * count;
    if output.is_null() || output_capacity < output_length {
        return -2;
    }
    *output = b'0';
    *output.add(1) = b'b';
    let mut position = 2;
    while count > 0 {
        count -= 1;
        let nibble = digits[count] + 3;
        for bit in (0..4).rev() {
            *output.add(position) = if nibble & (1 << bit) != 0 { b'1' } else { b'0' };
            position += 1;
        }
    }
    output_length as i64
}
