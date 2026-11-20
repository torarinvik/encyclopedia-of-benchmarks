const MAX_TERMS: usize = 8;
const MAX_INPUT_LENGTH: usize = 19;
const MODULUS: i64 = 998_244_353;

fn normalize(value: i64) -> i64 {
    let remainder = value % MODULUS;
    if remainder < 0 { remainder + MODULUS } else { remainder }
}

fn power(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1_i64;
    base = normalize(base);
    while exponent > 0 {
        if exponent & 1 != 0 { result = result * base % MODULUS; }
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    result
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for (index, byte) in bytes.iter().enumerate() {
        unsafe { *output.add(offset + index) = *byte; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn lentz_continued_fraction_convergents(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let count_value = values[0];
    if !(1..=MAX_TERMS as i64).contains(&count_value) { return -1; }
    let count = count_value as usize;
    if length != 2 + 2 * count { return -1; }
    if values[1..].iter().any(|value| *value < 0 || *value >= MODULUS) { return -1; }
    let mut value = values[1];
    if value == 0 { return -1; }
    let mut c_ratio = value;
    let mut d_ratio = 0_i64;
    let mut trace = [0_i64; MAX_TERMS + 2];
    trace[0] = value;
    for index in 0..count {
        let numerator = values[2 + 2 * index];
        let denominator = values[3 + 2 * index];
        let d_denominator = normalize(denominator + numerator * d_ratio);
        if d_denominator == 0 || c_ratio == 0 { return -1; }
        let c_value = normalize(denominator + numerator * power(c_ratio, MODULUS - 2));
        if c_value == 0 { return -1; }
        d_ratio = power(d_denominator, MODULUS - 2);
        value = value * c_value % MODULUS * d_ratio % MODULUS;
        c_ratio = c_value;
        trace[index + 1] = value;
    }
    let output_bytes = 8 * (count + 2);
    if output.is_null() || capacity < output_bytes { return -2; }
    unsafe { store_i64_le(output, 0, (count + 1) as i64); }
    for i in 0..=count {
        unsafe { store_i64_le(output, 8 * (i + 1), trace[i]); }
    }
    output_bytes as i64
}
