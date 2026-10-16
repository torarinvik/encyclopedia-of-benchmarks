const Q12_OFFSET: i64 = 10_000_000_000;
const Q6_DIVISOR: i64 = 1_000_000;

fn round_div_even(numerator: i64, denominator: i64) -> i64 {
    let negative = numerator < 0;
    let magnitude = numerator.unsigned_abs();
    let divisor = denominator as u64;
    let mut quotient = magnitude / divisor;
    let remainder = magnitude % divisor;
    if remainder * 2 > divisor || (remainder * 2 == divisor && quotient & 1 != 0) {
        quotient += 1;
    }
    if negative { -(quotient as i64) } else { quotient as i64 }
}

fn put_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn barnsley_fern(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length == 0 { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    let iteration_value = input[0];
    if !(1..=4096).contains(&iteration_value) || length != iteration_value as usize { return -1; }
    let iterations = iteration_value as usize;
    if input[1..].iter().any(|sample| !(0..10_000).contains(sample)) { return -1; }
    let output_length = iterations * 16;
    if output.is_null() || capacity < output_length { return -2; }

    let output = std::slice::from_raw_parts_mut(output, output_length);
    let (mut x, mut y) = (0_i64, 0_i64);
    put_i64_le(output, 0, 0);
    put_i64_le(output, 8, 0);
    for step in 1..iterations {
        let sample = input[step];
        let (a, b, c, d, f) = if sample < 100 {
            (0, 0, 0, 16, 0)
        } else if sample < 8_600 {
            (85, 4, -4, 85, 160)
        } else if sample < 9_300 {
            (20, -26, 23, 22, 160)
        } else {
            (-15, 28, 26, 24, 44)
        };
        let next_x = round_div_even(a * x + b * y, 100);
        let next_y = round_div_even(c * x + d * y, 100) + f * Q12_OFFSET;
        x = next_x;
        y = next_y;
        put_i64_le(output, step * 16, round_div_even(x, Q6_DIVISOR));
        put_i64_le(output, step * 16 + 8, round_div_even(y, Q6_DIVISOR));
    }
    output_length as i64
}
