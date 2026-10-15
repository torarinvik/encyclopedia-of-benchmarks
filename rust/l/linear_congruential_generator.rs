fn put_u64_le(output: *mut u8, offset: usize, value: u64) {
    let bytes = value.to_le_bytes();
    unsafe { std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(offset), bytes.len()); }
}

#[no_mangle]
pub unsafe extern "C" fn linear_congruential_generator(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length != 5 { return -1; }
    let x = std::slice::from_raw_parts(input, 5);
    let (seed, multiplier, increment, modulo, count) = (x[0], x[1], x[2], x[3], x[4]);
    if modulo < 2 || modulo > 4_294_967_296 || seed < 0 || seed >= modulo || multiplier < 0 || multiplier > 65_535 || increment < 0 || increment > 4_294_967_295 || count < 0 || count > 512 { return -1; }
    let n = count as usize; let required = n * 8;
    if capacity < required || (required > 0 && output.is_null()) { return -2; }
    let mut state = seed as u64;
    for i in 0..n {
        state = ((multiplier as u64 * state) + increment as u64) % modulo as u64;
        put_u64_le(output, i * 8, state);
    }
    required as i64
}
