const MAX_COMPONENT: i64 = 100_000;
const OUTPUT_BYTES: usize = 16;

#[no_mangle]
pub unsafe extern "C" fn complex_arithmetic(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length != 5 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let operation = values[0];
    let ar = values[1]; let ai = values[2]; let br = values[3]; let bi = values[4];
    if !(0..=5).contains(&operation) || [ar, ai, br, bi].iter().any(|value| *value < -MAX_COMPONENT || *value > MAX_COMPONENT) {
        return -1;
    }
    let (real_result, imaginary_result) = match operation {
        0 => (ar + br, ai + bi),
        1 => (ar - br, ai - bi),
        2 => (ar * br - ai * bi, ar * bi + ai * br),
        3 => {
            let denominator = br * br + bi * bi;
            if denominator == 0 { return -1; }
            let real_numerator = ar * br + ai * bi;
            let imaginary_numerator = ai * br - ar * bi;
            if real_numerator % denominator != 0 || imaginary_numerator % denominator != 0 { return -1; }
            (real_numerator / denominator, imaginary_numerator / denominator)
        },
        4 => (ar, -ai),
        _ => (if ar == br && ai == bi { 1 } else { 0 }, 0),
    };
    if output_capacity < OUTPUT_BYTES || output.is_null() { return -2; }
    std::ptr::copy_nonoverlapping(real_result.to_le_bytes().as_ptr(), output, 8);
    std::ptr::copy_nonoverlapping(imaginary_result.to_le_bytes().as_ptr(), output.add(8), 8);
    2
}
