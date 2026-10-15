/// Exchange each adjacent pair of low 30 bits.
#[no_mangle]
pub extern "C" fn swap_adjacent_bits(input: i64) -> i64 {
    if !(0..=1_073_741_823).contains(&input) { return -1; }
    let value = input as u32;
    (((value & 0xAAAAAAAA) >> 1) | ((value & 0x55555555) << 1)) as i64
}
