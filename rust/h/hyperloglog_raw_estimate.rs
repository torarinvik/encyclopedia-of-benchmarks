fn gcd(mut a: u64, mut b: u64) -> u64 {
    while b != 0 { let remainder = a % b; a = b; b = remainder; }
    a
}

#[no_mangle]
pub unsafe extern "C" fn hyperloglog_raw_estimate(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(1..=130).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=128).contains(&values[0]) || length != values[0] as usize + 1 { return -1; }
    let mut registers = [0u8; 16];
    for &value in &values[1..] {
        if !(0..=u32::MAX as i64).contains(&value) { return -1; }
        let hash = value as u32;
        let bucket = (hash >> 28) as usize;
        let suffix = hash & 0x0fff_ffff;
        let rank = (suffix.leading_zeros() - 4 + 1) as u8;
        registers[bucket] = registers[bucket].max(rank);
    }
    let sum: u64 = registers.iter().map(|&rank| 1u64 << (29-rank)).sum();
    let (mut numerator, mut denominator) = (673u64*256*(1u64<<29), 1000*sum);
    let factor = gcd(numerator, denominator);
    numerator /= factor; denominator /= factor;
    if output.is_null() || capacity < 144 { return -2; }
    let mut staged = [0u8; 144];
    staged[..8].copy_from_slice(&numerator.to_le_bytes());
    staged[8..16].copy_from_slice(&denominator.to_le_bytes());
    for (i, rank) in registers.iter().enumerate() {
        staged[16+8*i..24+8*i].copy_from_slice(&(*rank as u64).to_le_bytes());
    }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, staged.len());
    144
}
