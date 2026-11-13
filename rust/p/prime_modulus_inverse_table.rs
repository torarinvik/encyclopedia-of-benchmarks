const MODULUS: i64 = 1_000_000_007;

#[no_mangle]
pub unsafe extern "C" fn prime_modulus_inverse_table(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=34).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=32).contains(&values[0]) { return -1; }
    let count = values[0] as usize;
    if length != count + 1 || values[1..].iter().any(|&v| !(1..=256).contains(&v)) {
        return -1;
    }
    if count == 0 { return 0; }
    let bytes = count * 4;
    if output.is_null() || capacity < bytes { return -2; }
    let maximum = *values[1..].iter().max().unwrap() as usize;
    let mut inverse = [0i64; 257];
    inverse[1] = 1;
    for i in 2..=maximum {
        let value = i as i64;
        inverse[i] = MODULUS - (MODULUS / value) * inverse[(MODULUS % value) as usize] % MODULUS;
    }
    let destination = std::slice::from_raw_parts_mut(output, bytes);
    for (chunk, &operand) in destination.chunks_exact_mut(4).zip(&values[1..]) {
        chunk.copy_from_slice(&(inverse[operand as usize] as u32).to_le_bytes());
    }
    bytes as i64
}
