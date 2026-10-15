fn unsigned_bits<const N: usize>(mut value: u32, bits: &mut [u8; N]) -> usize {
    let mut length = 0;
    loop {
        bits[length] = b'0' + (value & 1) as u8;
        length += 1;
        value >>= 1;
        if value == 0 { break; }
    }
    bits[..length].reverse();
    length
}

#[no_mangle]
pub extern "C" fn binary_shifts(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length != 3 { return -1; }
    let (operation, number, shift) = unsafe { (*values, *values.add(1), *values.add(2)) };
    if !(0..=2).contains(&operation) || !(-2_147_483_647..=2_147_483_647).contains(&number)
        || !(0..=31).contains(&shift) || (operation < 2 && number < 0) { return -1; }

    let mut bits = [0u8; 80];
    let mut result = [0u8; 82];
    let mut bits_length = 0usize;
    let mut result_length = 0usize;
    if operation == 0 || operation == 1 {
        bits_length = unsigned_bits(number as u32, &mut bits);
        result[0] = b'0'; result[1] = b'b'; result_length = 2;
        if operation == 0 {
            result[result_length..result_length + bits_length].copy_from_slice(&bits[..bits_length]);
            result_length += bits_length;
            for _ in 0..shift { result[result_length] = b'0'; result_length += 1; }
        } else if shift as usize >= bits_length {
            result[result_length] = b'0'; result_length += 1;
        } else {
            let kept = bits_length - shift as usize;
            result[result_length..result_length + kept].copy_from_slice(&bits[..kept]);
            result_length += kept;
        }
    } else {
        if number >= 0 {
            bits[0] = b'0';
            let mut remaining_bits = [0u8; 79];
            let remaining_length = unsigned_bits(number as u32, &mut remaining_bits);
            bits[1..1 + remaining_length].copy_from_slice(&remaining_bits[..remaining_length]);
            bits_length = 1 + remaining_length;
        } else {
            let magnitude = (-number) as u32;
            let magnitude_length = unsigned_bits(magnitude, &mut bits);
            let complement = (1u32 << magnitude_length) - magnitude;
            let mut complement_bits = [0u8; 40];
            let complement_length = unsigned_bits(complement, &mut complement_bits);
            bits[0] = b'1';
            let mut position = 1;
            for _ in complement_length..magnitude_length { bits[position] = b'0'; position += 1; }
            bits[position..position + complement_length].copy_from_slice(&complement_bits[..complement_length]);
            bits_length = position + complement_length;
        }
        result[0] = b'0'; result[1] = b'b'; result_length = 2;
        let sign = bits[0];
        if shift as usize >= bits_length {
            for _ in 0..bits_length { result[result_length] = sign; result_length += 1; }
        } else {
            for _ in 0..shift { result[result_length] = sign; result_length += 1; }
            let kept = bits_length - shift as usize;
            result[result_length..result_length + kept].copy_from_slice(&bits[..kept]);
            result_length += kept;
        }
    }
    if output.is_null() || output_capacity < result_length { return -2; }
    unsafe { core::ptr::copy_nonoverlapping(result.as_ptr(), output, result_length); }
    result_length as i64
}
