/// Convert a uint16 value to lowercase digits in a base from 2 through 16.
const MAX_VALUE: i64 = 65535;
const SYMBOLS: &[u8; 16] = b"0123456789abcdef";

#[no_mangle]
pub unsafe extern "C" fn int_to_string(packed: i64, output: *mut u8,
                                         output_capacity: usize) -> i64 {
    if packed < 0 { return -1; }
    let value = packed / 15;
    let base = packed % 15 + 2;
    if value > MAX_VALUE { return -1; }
    let mut digits = [0u8; 16];
    let mut count = 0usize;
    let mut remaining = value;
    loop {
        digits[count] = SYMBOLS[(remaining % base) as usize];
        count += 1;
        remaining /= base;
        if remaining == 0 { break; }
    }
    let required = count + 1;
    if output.is_null() || output_capacity < required { return -2; }
    for index in 0..count { *output.add(index) = digits[count - index - 1]; }
    *output.add(count) = 0;
    required as i64
}
