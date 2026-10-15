/// Add two most-significant-first binary digit arrays.
#[no_mangle]
pub unsafe extern "C" fn binary_addition(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 { return -1; }

    let length_a_value = *values;
    let length_b_value = *values.add(1);
    if !(0..=2047).contains(&length_a_value) || !(0..=2047).contains(&length_b_value) {
        return -1;
    }

    let length_a = length_a_value as usize;
    let length_b = length_b_value as usize;
    if length != 2 + length_a + length_b { return -1; }

    for index in 0..length_a + length_b {
        let bit = *values.add(2 + index);
        if !(0..=1).contains(&bit) { return -1; }
    }

    let width = length_a.max(length_b);
    let mut carry = 0;
    for offset in 0..width {
        let bit_a = if offset < length_a {
            *values.add(2 + length_a - 1 - offset) as i32
        } else { 0 };
        let bit_b = if offset < length_b {
            *values.add(2 + length_a + length_b - 1 - offset) as i32
        } else { 0 };
        carry = (bit_a + bit_b + carry) >> 1;
    }
    let result_length = width + carry as usize;
    if result_length == 0 { return 0; }
    if output.is_null() || output_capacity < result_length { return -2; }

    carry = 0;
    for offset in 0..width {
        let bit_a = if offset < length_a {
            *values.add(2 + length_a - 1 - offset) as i32
        } else { 0 };
        let bit_b = if offset < length_b {
            *values.add(2 + length_a + length_b - 1 - offset) as i32
        } else { 0 };
        let sum = bit_a + bit_b + carry;
        let destination = result_length - 1 - offset;
        *output.add(destination) = b'0' + (sum & 1) as u8;
        carry = sum >> 1;
    }
    if carry != 0 { *output = b'1'; }
    result_length as i64
}
