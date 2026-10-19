const OUTPUT_BYTES: usize = 12;

fn reverse_bits32(mut n: u32) -> u32 {
    n = ((n >> 1) & 0x5555_5555) | ((n & 0x5555_5555) << 1);
    n = ((n >> 2) & 0x3333_3333) | ((n & 0x3333_3333) << 2);
    n = ((n >> 4) & 0x0f0f_0f0f) | ((n & 0x0f0f_0f0f) << 4);
    ((n & 0xff00_0000) >> 24) | ((n & 0x00ff_0000) >> 8) |
        ((n & 0x0000_ff00) << 8) | ((n & 0x0000_00ff) << 24)
}

fn reverse_bits64(mut n: u64) -> u64 {
    n = ((n >> 1) & 0x5555_5555_5555_5555) | ((n & 0x5555_5555_5555_5555) << 1);
    n = ((n >> 2) & 0x3333_3333_3333_3333) | ((n & 0x3333_3333_3333_3333) << 2);
    n = ((n >> 4) & 0x0f0f_0f0f_0f0f_0f0f) | ((n & 0x0f0f_0f0f_0f0f_0f0f) << 4);
    ((n & 0xff00_0000_0000_0000) >> 56) | ((n & 0x00ff_0000_0000_0000) >> 40) |
        ((n & 0x0000_ff00_0000_0000) >> 24) | ((n & 0x0000_00ff_0000_0000) >> 8) |
        ((n & 0x0000_0000_ff00_0000) << 8) | ((n & 0x0000_0000_00ff_0000) << 24) |
        ((n & 0x0000_0000_0000_ff00) << 40) | ((n & 0x0000_0000_0000_00ff) << 56)
}

#[no_mangle]
pub unsafe extern "C" fn revert_bits(input: *const i64, length: usize,
                                     output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > u32::MAX as i64 { return -1; }
    if output.is_null() || capacity < OUTPUT_BYTES { return -2; }
    let reversed32 = reverse_bits32(values[0] as u32).to_le_bytes();
    let reversed64 = reverse_bits64(values[1] as u64).to_le_bytes();
    std::ptr::copy_nonoverlapping(reversed32.as_ptr(), output, reversed32.len());
    std::ptr::copy_nonoverlapping(reversed64.as_ptr(), output.add(4), reversed64.len());
    OUTPUT_BYTES as i64
}
