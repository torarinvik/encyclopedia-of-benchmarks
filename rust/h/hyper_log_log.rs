const MAX_COUNT: usize = 1024;
const REGISTER_COUNT: usize = 65_536;

#[no_mangle]
pub extern "C" fn hyper_log_log(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_COUNT + 1 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let count64 = values[0];
    if count64 < 1 || count64 > MAX_COUNT as i64 || length != count64 as usize + 1 { return -1; }
    let count = count64 as usize;
    if values[1..].iter().any(|&value| !(1..=65_535).contains(&value)) { return -1; }

    let mut registers = [0u8; REGISTER_COUNT];
    let mut seen = [0u8; REGISTER_COUNT];
    let mut touched = [0u16; MAX_COUNT];
    let mut touched_count = 0usize;
    for &value64 in &values[1..] {
        let value = value64 as u32;
        let index = value as usize;
        let rank = value.trailing_zeros() as u8;
        if seen[index] == 0 { seen[index] = 1; touched[touched_count] = value as u16; touched_count += 1; }
        if rank > registers[index] { registers[index] = rank; }
    }

    let mut z = 0.0;
    for &index in &touched[..touched_count] { z += 1.0 / f64::from(1u32 << registers[index as usize]); }
    let k = touched_count as f64;
    (0.673 * k * (k / z)).ceil() as i64
}
