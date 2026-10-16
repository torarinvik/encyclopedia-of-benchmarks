const MAX_SAMPLE_COUNT: usize = 128;

fn round_three_decimals(value: f64) -> f64 {
    let bits = value.to_bits();
    let negative = (bits >> 63) != 0;
    let exponent = ((bits >> 52) & 0x7ff) as i32;
    let fraction = bits & ((1_u64 << 52) - 1);
    let significand = if exponent == 0 { fraction } else { fraction | (1_u64 << 52) };
    let exponent2 = if exponent == 0 { -1074 } else { exponent - 1023 - 52 };
    let scaled = significand * 1000;
    let mut rounded = 0_u64;
    if exponent2 >= 0 {
        rounded = scaled << exponent2;
    } else {
        let shift = (-exponent2) as u32;
        if shift < 64 {
            rounded = scaled >> shift;
            if shift > 0 {
                let remainder = scaled & ((1_u64 << shift) - 1);
                let half = 1_u64 << (shift - 1);
                if remainder > half || (remainder == half && (rounded & 1) != 0) {
                    rounded += 1;
                }
            }
        }
    }
    let result = rounded as f64 / 1000.0;
    if negative { -result } else { result }
}

fn put_f64_le(output: &mut [u8], offset: usize, value: f64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn data_transformations(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length < 4 || length > MAX_SAMPLE_COUNT + 2 { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let mode = values[0];
    let count_arg = values[1];
    if (mode != 0 && mode != 1) || !(2..=MAX_SAMPLE_COUNT as i64).contains(&count_arg)
        || length != count_arg as usize + 2 { return -1; }
    let count = count_arg as usize;
    let sample = &values[2..];
    if sample.iter().any(|&value| !(-100_000..=100_000).contains(&value)) { return -1; }
    let minimum = *sample.iter().min().unwrap();
    let maximum = *sample.iter().max().unwrap();
    if minimum == maximum { return -1; }
    let output_bytes = count * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    let destination = std::slice::from_raw_parts_mut(output, output_bytes);
    if mode == 0 {
        let span = (maximum - minimum) as f64;
        for (index, &value) in sample.iter().enumerate() {
            let normalized = (value - minimum) as f64 / span;
            put_f64_le(destination, index * 8, round_three_decimals(normalized));
        }
    } else {
        let sum: i64 = sample.iter().sum();
        let sum_squares: i64 = sample.iter().map(|&value| value * value).sum();
        let average = sum as f64 / count as f64;
        let variance_numerator = count as i64 * sum_squares - sum * sum;
        let variance_denominator = (count * (count - 1)) as f64;
        let deviation = ((variance_numerator as f64) / variance_denominator).sqrt();
        for (index, &value) in sample.iter().enumerate() {
            let standardized = (value as f64 - average) / deviation;
            put_f64_le(destination, index * 8, round_three_decimals(standardized));
        }
    }
    output_bytes as i64
}
