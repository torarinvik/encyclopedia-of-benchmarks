const MODULUS: i64 = 998_244_353;

#[no_mangle]
pub unsafe extern "C" fn prefix_sum_of_binomial_coefficient(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(3..=34).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let count_value = values[0];
    if !(1..=16).contains(&count_value) {
        return -1;
    }
    let count = count_value as usize;
    if length != 1 + 2 * count {
        return -1;
    }
    let mut ns = [0i64; 16];
    let mut ks = [0i64; 16];
    for query in 0..count {
        ns[query] = values[1 + 2 * query];
        ks[query] = values[2 + 2 * query];
        if ns[query] < 0 || ns[query] > 128 || ks[query] < 0 || ks[query] > ns[query] {
            return -1;
        }
    }
    let output_length = 4 * count;
    if output.is_null() || capacity < output_length {
        return -2;
    }

    let mut inverse = [0i64; 129];
    inverse[1] = 1;
    for value in 2..=128 {
        let v = value as i64;
        inverse[value] = MODULUS - (MODULUS / v) * inverse[(MODULUS % v) as usize] % MODULUS;
    }
    for query in 0..count {
        let mut coefficient = 1i64;
        let mut prefix = 1i64;
        for index in 0..ks[query] {
            coefficient = coefficient * (ns[query] - index) % MODULUS;
            coefficient = coefficient * inverse[(index + 1) as usize] % MODULUS;
            prefix = (prefix + coefficient) % MODULUS;
        }
        let residue = prefix as u32;
        let offset = 4 * query;
        *output.add(offset) = residue as u8;
        *output.add(offset + 1) = (residue >> 8) as u8;
        *output.add(offset + 2) = (residue >> 16) as u8;
        *output.add(offset + 3) = (residue >> 24) as u8;
    }
    output_length as i64
}
