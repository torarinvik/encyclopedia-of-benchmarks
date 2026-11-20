fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    unsafe { std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(offset), 8); }
}

#[no_mangle]
pub unsafe extern "C" fn continued_fraction_convergents(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=18).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let count_value = values[0];
    if !(1..=16).contains(&count_value) || !(-1000..=1000).contains(&values[1]) { return -1; }
    let count = count_value as usize;
    if length != count + 1 || values[2..].iter().any(|&value| !(1..=8).contains(&value)) { return -1; }
    let required = 16 * count;
    if output.is_null() || capacity < required { return -2; }

    let mut p_two_back = 0i64;
    let mut p_one_back = 1i64;
    let mut q_two_back = 1i64;
    let mut q_one_back = 0i64;
    for index in 0..count {
        let p = values[index + 1] * p_one_back + p_two_back;
        let q = values[index + 1] * q_one_back + q_two_back;
        store_i64_le(output, 16 * index, p);
        store_i64_le(output, 16 * index + 8, q);
        p_two_back = p_one_back; p_one_back = p;
        q_two_back = q_one_back; q_one_back = q;
    }
    required as i64
}
