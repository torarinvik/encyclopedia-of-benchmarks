/// One majority-clock step for the three source-configured A5 LFSRs.
fn write_i64_le(output: *mut u8, offset: usize, value: i64) {
    for (byte, item) in value.to_le_bytes().iter().enumerate() {
        unsafe { output.add(offset + byte).write(*item); }
    }
}

#[no_mangle]
pub extern "C" fn composite_lfsr_majority_clock(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, 3) };
    if values[0] < 0 || values[0] > 524287 || values[1] < 0 || values[1] > 4194303 || values[2] < 0 || values[2] > 8388607 {
        return -1;
    }
    if output.is_null() || output_capacity < 32 { return -2; }
    let mut s1 = values[0] as u64; let mut s2 = values[1] as u64; let mut s3 = values[2] as u64;
    let c1 = (s1 >> 8) & 1; let c2 = (s2 >> 10) & 1; let c3 = (s3 >> 10) & 1;
    let majority = c1 + c2 + c3 >= 2;
    let emitted = ((s1 >> 18) ^ (s2 >> 21) ^ (s3 >> 22)) & 1;
    if (c1 == 1) == majority { s1 = ((s1 << 1) & 524287) | (((s1 >> 13) ^ (s1 >> 16) ^ (s1 >> 17) ^ (s1 >> 18)) & 1); }
    if (c2 == 1) == majority { s2 = ((s2 << 1) & 4194303) | (((s2 >> 20) ^ (s2 >> 21)) & 1); }
    if (c3 == 1) == majority { s3 = ((s3 << 1) & 8388607) | (((s3 >> 7) ^ (s3 >> 20) ^ (s3 >> 21) ^ (s3 >> 22)) & 1); }
    write_i64_le(output, 0, emitted as i64); write_i64_le(output, 8, s1 as i64);
    write_i64_le(output, 16, s2 as i64); write_i64_le(output, 24, s3 as i64);
    32
}
