/// Emit the pinned minimal-width two's-complement string for a signed integer.
#[no_mangle]
pub extern "C" fn twos_complement(value: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if value > 0 { return -1; }
    if value == 0 {
        if output.is_null() || output_capacity < 3 { return -2; }
        unsafe {
            output.add(0).write(b'0');
            output.add(1).write(b'b');
            output.add(2).write(b'0');
        }
        return 3;
    }
    let magnitude = value.wrapping_neg() as u64;
    let bit_length = 64 - magnitude.leading_zeros() as usize;
    let suffix = if bit_length == 64 { magnitude } else { (1u64 << bit_length) - magnitude };
    let mut bits = [0u8; 64];
    let mut bit_count = 0usize;
    let mut remaining = suffix;
    while remaining > 0 {
        bits[bit_count] = b'0' + (remaining & 1) as u8;
        bit_count += 1;
        remaining >>= 1;
    }
    let required = bit_length + 3;
    if output.is_null() || output_capacity < required { return -2; }
    let mut position = 0usize;
    unsafe {
        output.add(position).write(b'0'); position += 1;
        output.add(position).write(b'b'); position += 1;
        output.add(position).write(b'1'); position += 1;
        for _ in bit_count..bit_length {
            output.add(position).write(b'0'); position += 1;
        }
        while bit_count > 0 {
            bit_count -= 1;
            output.add(position).write(bits[bit_count]);
            position += 1;
        }
    }
    position as i64
}
