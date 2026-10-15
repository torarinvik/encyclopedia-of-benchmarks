/// Encode the C# uint overload as exactly 32 ASCII binary digits.
#[no_mangle]
pub unsafe extern "C" fn int2_binary(value: i64, output: *mut u8,
                                       output_capacity: usize) -> i64 {
    if !(0..=u32::MAX as i64).contains(&value) {
        return -1;
    }
    if output.is_null() || output_capacity < 32 {
        return -2;
    }

    let mut remaining = value as u32;
    let mut most_significant_bit = 0x8000_0000u32;
    for i in 0..32 {
        if remaining >= most_significant_bit {
            *output.add(i) = b'1';
            remaining -= most_significant_bit;
        } else {
            *output.add(i) = b'0';
        }
        most_significant_bit /= 2;
    }
    32
}
