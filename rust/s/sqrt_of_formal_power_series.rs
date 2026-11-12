const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 64;
const MAX_INPUT: usize = 66;

fn mod_power(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1_i64;
    while exponent > 0 {
        if exponent % 2 != 0 { result = result * base % MODULUS; }
        base = base * base % MODULUS;
        exponent /= 2;
    }
    result
}

fn mod_square_root(value: i64) -> i64 {
    if value == 0 { return 0; }
    if mod_power(value, (MODULUS - 1) / 2) != 1 { return -1; }
    let mut odd_part = MODULUS - 1;
    let mut twos = 0_usize;
    while odd_part % 2 == 0 { odd_part /= 2; twos += 1; }
    let mut non_residue = 2_i64;
    while mod_power(non_residue, (MODULUS - 1) / 2) != MODULUS - 1 { non_residue += 1; }
    let mut c = mod_power(non_residue, odd_part);
    let mut root = mod_power(value, (odd_part + 1) / 2);
    let mut remainder = mod_power(value, odd_part);
    let mut order = twos;
    while remainder != 1 {
        let mut index = 1_usize;
        let mut probe = remainder * remainder % MODULUS;
        while index < order && probe != 1 { probe = probe * probe % MODULUS; index += 1; }
        if index >= order || probe != 1 { return -1; }
        let mut exponent = 1_i64;
        for _ in 0..(order - index - 1) { exponent *= 2; }
        let factor = mod_power(c, exponent);
        root = root * factor % MODULUS;
        let factor_squared = factor * factor % MODULUS;
        remainder = remainder * factor_squared % MODULUS;
        c = factor_squared;
        order = index;
    }
    root.min(MODULUS - root)
}

unsafe fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn sqrt_of_formal_power_series(input: *const i64, length: usize,
                                                       output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 1 || input[0] > MAX_N as i64 { return -1; }
    let n = input[0] as usize;
    if length != n + 1 { return -1; }
    if input[1..].iter().any(|&value| value < 0 || value >= MODULUS) { return -1; }
    let bytes = 8 * n;
    if output.is_null() || capacity < bytes { return -2; }

    let mut result = [0_i64; MAX_N];
    let mut valuation = 0_usize;
    while valuation < n && input[valuation + 1] == 0 { valuation += 1; }
    if valuation == n {
        for i in 0..n { unsafe { store_le(output, 8 * i, 0); } }
        return bytes as i64;
    }
    if valuation % 2 != 0 {
        unsafe { store_le(output, 0, -1); }
        return 8;
    }
    let shift = valuation / 2;
    let leading_root = mod_square_root(input[valuation + 1]);
    if leading_root < 0 {
        unsafe { store_le(output, 0, -1); }
        return 8;
    }
    let inverse_twice_root = mod_power(2 * leading_root % MODULUS, MODULUS - 2);
    let width = n - valuation;
    result[shift] = leading_root;
    for degree in 1..width {
        let mut cross_terms = 0_i64;
        for i in 1..degree {
            cross_terms = (cross_terms + result[shift + i] * result[shift + degree - i]) % MODULUS;
        }
        let mut delta = (input[valuation + degree + 1] - cross_terms) % MODULUS;
        if delta < 0 { delta += MODULUS; }
        result[shift + degree] = delta * inverse_twice_root % MODULUS;
    }
    for i in 0..n { unsafe { store_le(output, 8 * i, result[i]); } }
    bytes as i64
}
