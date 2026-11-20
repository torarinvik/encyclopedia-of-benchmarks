const MODULUS: i64 = 998_244_353;
const MAX_NODES: usize = 12;
const MAX_LENGTH: usize = 27;

fn mod_pow(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1_i64;
    while exponent > 0 {
        if exponent & 1 != 0 { result = result * base % MODULUS; }
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn newton_divided_difference_interpolation(
        input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(4..=MAX_LENGTH).contains(&length) { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    if !(1..=MAX_NODES as i64).contains(&words[0]) { return -1; }
    let count = words[0] as usize;
    if length != 2 + 2 * count { return -1; }
    let mut nodes = [0_i64; MAX_NODES];
    let mut differences = [0_i64; MAX_NODES];
    for i in 0..count {
        nodes[i] = words[1 + i];
        differences[i] = words[1 + count + i];
        if !(0..MODULUS).contains(&nodes[i]) || !(0..MODULUS).contains(&differences[i]) { return -1; }
        if nodes[..i].contains(&nodes[i]) { return -1; }
    }
    let query = words[length - 1];
    if !(0..MODULUS).contains(&query) { return -1; }
    for order in 1..count {
        for i in (order..count).rev() {
            let mut numerator = differences[i] - differences[i - 1];
            if numerator < 0 { numerator += MODULUS; }
            let mut denominator = nodes[i] - nodes[i - order];
            if denominator < 0 { denominator += MODULUS; }
            differences[i] = numerator * mod_pow(denominator, MODULUS - 2) % MODULUS;
        }
    }
    let mut result = differences[count - 1];
    for i in (0..count - 1).rev() {
        let mut factor = query - nodes[i];
        if factor < 0 { factor += MODULUS; }
        result = (result * factor + differences[i]) % MODULUS;
    }
    result
}
