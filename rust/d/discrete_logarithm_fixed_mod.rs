#[no_mangle]
pub unsafe extern "C" fn discrete_logarithm_fixed_mod(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(3..=259).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(2..=4093).contains(&values[0]) || values[1] < 1 || values[1] >= values[0]
        || !(1..=256).contains(&values[2]) { return -1; }
    let (p, g, n) = (values[0] as usize, values[1] as usize, values[2] as usize);
    if length != n + 3 { return -1; }
    let mut divisor = 2;
    while divisor * divisor <= p {
        if p % divisor == 0 { return -1; }
        divisor += 1;
    }
    if values[3..].iter().any(|&x| x < 1 || x >= p as i64) { return -1; }
    let mut table = [-1i16; 4094];
    let mut residue = 1;
    for exponent in 0..p-1 {
        if table[residue] != -1 { return -1; }
        table[residue] = exponent as i16;
        residue = residue * g % p;
    }
    if residue != 1 { return -1; }
    if output.is_null() || capacity < 8*n { return -2; }
    for (i, &target) in values[3..].iter().enumerate() {
        let bytes = (table[target as usize] as i64).to_le_bytes();
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(8*i), 8);
    }
    (8*n) as i64
}
