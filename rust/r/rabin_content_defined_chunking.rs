fn reduce(mut value: u32) -> u16 {
    for bit in (16..32).rev() {
        if value & (1u32 << bit) != 0 { value ^= 0x1100bu32 << (bit - 16); }
    }
    value as u16
}

#[no_mangle]
pub unsafe extern "C" fn rabin_content_defined_chunking(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=65).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=64).contains(&values[0]) { return -1; }
    let n = values[0] as usize;
    if length != n + 1 || values[1..].iter().any(|v| !(0..=255).contains(v)) { return -1; }
    let mut outgoing = [0u16; 256];
    for (byte, contribution) in outgoing.iter_mut().enumerate() { *contribution = reduce((byte as u32) << 24); }
    let mut fingerprint = 0u16;
    let mut boundaries = [0u8; 64];
    let mut count = 0;
    for i in 0..n {
        fingerprint = reduce(((fingerprint as u32) << 8) | values[i + 1] as u32);
        if i >= 4 { fingerprint ^= outgoing[values[i - 3] as usize]; }
        if fingerprint & 7 == 0 { boundaries[count] = (i + 1) as u8; count += 1; }
    }
    if n > 0 && (count == 0 || boundaries[count - 1] as usize != n) {
        boundaries[count] = n as u8;
        count += 1;
    }
    if output.is_null() || capacity < count { return -2; }
    std::ptr::copy_nonoverlapping(boundaries.as_ptr(), output, count);
    count as i64
}
