#[no_mangle]
pub unsafe extern "C" fn hyperloglog_corrected_estimate(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(1..=130).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=128).contains(&values[0]) || length != values[0] as usize + 1 { return -1; }
    let mut registers = [0u8; 16];
    for &value in &values[1..] {
        if !(0..=u32::MAX as i64).contains(&value) { return -1; }
        let hash = value as u32;
        let bucket = (hash >> 28) as usize;
        let rank = ((hash & 0x0fff_ffff).leading_zeros() - 3) as u8;
        registers[bucket] = registers[bucket].max(rank);
    }
    let sum: u64 = registers.iter().map(|&rank| 1u64 << (29-rank)).sum();
    let zeros = registers.iter().filter(|&&rank| rank == 0).count();
    let mut estimate = (673.0 * 256.0 * ((1u64 << 29) as f64)) / (1000.0 * sum as f64);
    let universe = 4294967296.0;
    if estimate <= 40.0 && zeros != 0 {
        estimate = 16.0 * (16.0 / zeros as f64).ln();
    } else if estimate > universe / 30.0 {
        if estimate >= universe { return -3; }
        estimate = -universe * (-estimate / universe).ln_1p();
    }
    if output.is_null() || capacity < 8 { return -2; }
    let staged = estimate.to_le_bytes();
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, 8);
    8
}
