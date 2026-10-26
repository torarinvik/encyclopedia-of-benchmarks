#[no_mangle]
pub unsafe extern "C" fn directed_perfect_phylogeny(input: *const i64, length: usize,
                                                     output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 146 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n0, m0) = (values[0], values[1]);
    if !(1..=12).contains(&n0) || !(1..=12).contains(&m0) || length != 2 + (n0 * m0) as usize { return -1; }
    let (n, m) = (n0 as usize, m0 as usize);
    let mut sets = [0u16; 12];
    for row in 0..n { for col in 0..m {
        let bit = values[2 + row * m + col];
        if bit != 0 && bit != 1 { return -1; }
        if bit == 1 { sets[col] |= 1u16 << row; }
    }}
    let mut feasible = true;
    for a in 0..m { for b in a + 1..m {
        let overlap = sets[a] & sets[b];
        if overlap != 0 && overlap != sets[a] && overlap != sets[b] { feasible = false; }
    }}
    if output.is_null() || capacity < 8 { return -2; }
    std::slice::from_raw_parts_mut(output, 8).copy_from_slice(&(feasible as i64).to_le_bytes());
    8
}
