fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn hypercube_edge_monotonicity_tester(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=130).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n_value = values[0];
    let q_value = values[1];
    if !(1..=6).contains(&n_value) || !(1..=32).contains(&q_value) { return -1; }
    let domain = 1usize << n_value as usize;
    let q = q_value as usize;
    if length != 2 + domain + 2 * q { return -1; }
    let table = &values[2..2 + domain];
    if table.iter().any(|&bit| bit != 0 && bit != 1) { return -1; }
    let tape = &values[2 + domain..];
    for pair in tape.chunks_exact(2) {
        if pair[0] < 0 || pair[0] as usize >= domain || pair[1] < 0 || pair[1] as usize >= n_value as usize { return -1; }
    }
    let mut accepted = 1i64;
    let mut rounds = 0i64;
    for pair in tape.chunks_exact(2) {
        let vertex = pair[0] as usize;
        let bit = 1usize << pair[1] as usize;
        let lower = vertex & !bit;
        rounds += 1;
        if table[lower] > table[lower | bit] { accepted = 0; break; }
    }
    if output.is_null() || capacity < 24 { return -2; }
    let result = unsafe { std::slice::from_raw_parts_mut(output, 24) };
    store_i64_le(result, 0, accepted);
    store_i64_le(result, 8, rounds);
    store_i64_le(result, 16, 2 * rounds);
    24
}
