fn put_i64(output: &mut [u8; 1544], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub extern "C" fn three_dimensional_moment_curve(input: *const i64, length: usize,
                                                   output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let n_raw = unsafe { *input };
    if !(0..=64).contains(&n_raw) { return -1; }
    let n = n_raw as usize; let bytes = 8 * (1 + 3 * n);
    if output.is_null() || capacity < bytes { return -2; }
    let mut staged = [0u8; 1544]; put_i64(&mut staged, 0, n as i64);
    for i in 1..=n {
        let x = i as i64; let offset = 8 * (1 + 3 * (i - 1));
        put_i64(&mut staged, offset, x); put_i64(&mut staged, offset + 8, x * x); put_i64(&mut staged, offset + 16, x * x * x);
    }
    unsafe { std::ptr::copy_nonoverlapping(staged.as_ptr(), output, bytes); }
    bytes as i64
}
