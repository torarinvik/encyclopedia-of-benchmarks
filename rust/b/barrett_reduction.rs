const MAX_MODULUS: i64 = 65_535;
const MAX_VALUES: usize = 12;
const MAX_LENGTH: usize = 15;
const RADIX: i64 = 4_294_967_296;

#[no_mangle]
pub unsafe extern "C" fn barrett_reduction(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=MAX_LENGTH).contains(&length) { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    let modulus = words[0];
    let count_value = words[1];
    if modulus < 2 || modulus > MAX_MODULUS || count_value < 0 || count_value > MAX_VALUES as i64 { return -1; }
    let count = count_value as usize;
    if length != 2 + count { return -1; }
    let square_bound = modulus * modulus;
    for &value in &words[2..] {
        if value < 0 || value >= square_bound { return -1; }
    }

    let reciprocal = RADIX / modulus;
    let mut checksum = 0_i64;
    for i in 0..count {
        let value = words[2 + i];
        let quotient = (value * reciprocal) / RADIX;
        let mut remainder = value - quotient * modulus;
        if remainder >= modulus { remainder -= modulus; }
        checksum += (i as i64 + 1) * (remainder + 1);
    }
    checksum
}
