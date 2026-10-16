#[no_mangle]
pub unsafe extern "C" fn jump_game(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 1025 { return -2; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=1024).contains(&values[0]) || length != values[0] as usize + 1 { return -2; }
    let jumps = &values[1..];
    if jumps.iter().any(|&jump| !(0..=1_000_000).contains(&jump)) { return -2; }
    let mut last_pos = jumps.len() - 1;
    for i in (0..jumps.len()).rev() {
        if i + jumps[i] as usize >= last_pos { last_pos = i; }
    }
    if last_pos == 0 { 1 } else { 0 }
}
