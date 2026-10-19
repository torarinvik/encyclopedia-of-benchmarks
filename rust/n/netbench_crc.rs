const MAX_LENGTH: usize = 256;
const POLYNOMIAL: u64 = 0x04c11db7;
const OUTPUT_MASK: u64 = 0xffff_ffff;

#[no_mangle]
pub extern "C" fn netbench_crc(values: *const i64, length: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && values.is_null()) { return -1; }
    let input = if length == 0 { &[][..] } else { unsafe { std::slice::from_raw_parts(values, length) } };
    if input.iter().any(|&value| !(0..=255).contains(&value)) { return -1; }

    let mut table = [0_u64; 256];
    for (byte, slot) in table.iter_mut().enumerate() {
        let mut remainder = (byte as u64) << 24;
        for _ in 0..8 {
            if remainder & 0x8000_0000 != 0 {
                remainder = (remainder << 1) ^ POLYNOMIAL;
            } else {
                remainder <<= 1;
            }
        }
        *slot = remainder;
    }

    let mut crc = 0_u64;
    for &value in input {
        let byte = value as u64;
        let table_index = (((crc >> 24) ^ byte) & 0xff) as usize;
        crc = (crc << 8) ^ table[table_index];
    }
    (crc & OUTPUT_MASK) as i64
}
