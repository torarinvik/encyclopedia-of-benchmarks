fn store_u64_le(output: &mut [u8], offset: usize, value: u64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn van_der_corput_sequence(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length != 3 {
        return -1;
    }
    let base = *input;
    let first_index = *input.add(1);
    let count = *input.add(2);
    if !(2..=16).contains(&base)
        || !(1..=4096).contains(&first_index)
        || !(0..=128).contains(&count)
        || (count > 0 && first_index + count - 1 > 4096)
    {
        return -1;
    }

    let output_bytes = count as usize * 16;
    if output.is_null() || output_capacity < output_bytes {
        return -2;
    }
    let output_slice = std::slice::from_raw_parts_mut(output, output_bytes);
    for offset in 0..count as usize {
        let mut index = first_index + offset as i64;
        let mut numerator = 0u64;
        let mut denominator = 1u64;
        while index > 0 {
            numerator = numerator * base as u64 + (index % base) as u64;
            denominator *= base as u64;
            index /= base;
        }
        let position = offset * 16;
        store_u64_le(output_slice, position, numerator);
        store_u64_le(output_slice, position + 8, denominator);
    }
    output_bytes as i64
}
