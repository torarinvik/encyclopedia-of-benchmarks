#[no_mangle]
pub unsafe extern "C" fn reservoir_sampling_algorithm_r(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(2..=130).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=64).contains(&values[0]) || values[1] < 0 || values[1] > values[0] { return -1; }
    let n = values[0] as usize;
    let k = values[1] as usize;
    if length != 2+2*n-k || values[2..2+n].iter().any(|x| !(-1_000_000..=1_000_000).contains(x)) { return -1; }
    for i in k..n {
        if values[2+n+i-k] < 0 || values[2+n+i-k] > i as i64 { return -1; }
    }
    if output.is_null() || capacity < 8*k { return -2; }
    let mut reservoir = [0_i64; 64];
    reservoir[..k].copy_from_slice(&values[2..2+k]);
    for i in k..n {
        let draw = values[2+n+i-k] as usize;
        if draw < k { reservoir[draw] = values[2+i]; }
    }
    for (i, value) in reservoir[..k].iter().enumerate() {
        let encoded = value.to_le_bytes();
        std::ptr::copy_nonoverlapping(encoded.as_ptr(), output.add(8*i), 8);
    }
    (8*k) as i64
}
