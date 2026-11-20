const MAX_INPUT: usize = 130;
const OUTPUT_BYTES: usize = 24;

#[no_mangle]
pub extern "C" fn blr_linearity_test(input: *const i64, length: usize,
                                       output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if !(1..=6).contains(&values[0]) || !(1..=32).contains(&values[1]) { return -1; }
    let n = values[0] as usize;
    let q = values[1] as usize;
    let domain = 1usize << n;
    if length != 2 + domain + 2*q { return -1; }
    let table = &values[2..2+domain];
    let tape = &values[2+domain..];
    if table.iter().any(|&entry| entry != 0 && entry != 1) { return -1; }
    if tape.iter().any(|&point| point < 0 || point as u64 >= domain as u64) { return -1; }

    let mut rounds = 0usize;
    let mut accepted = 1i64;
    for pair in tape.chunks_exact(2) {
        let x = pair[0] as usize;
        let y = pair[1] as usize;
        rounds += 1;
        if (table[x] ^ table[y]) != table[x ^ y] { accepted = 0; break; }
    }
    if output.is_null() || capacity < OUTPUT_BYTES { return -2; }
    let mut staged = [0u8; OUTPUT_BYTES];
    staged[0..8].copy_from_slice(&accepted.to_le_bytes());
    staged[8..16].copy_from_slice(&(rounds as i64).to_le_bytes());
    staged[16..24].copy_from_slice(&((3*rounds) as i64).to_le_bytes());
    unsafe { std::ptr::copy_nonoverlapping(staged.as_ptr(), output, OUTPUT_BYTES); }
    OUTPUT_BYTES as i64
}
