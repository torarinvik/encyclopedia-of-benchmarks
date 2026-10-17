const MAX_DIMENSION: usize = 8;
const MAX_INPUT_ELEMENTS: usize = 5;
const MAX_PARSEABLE_INPUT_ELEMENTS: usize = 6;
const MAX_OUTPUT_ELEMENTS: usize = MAX_DIMENSION * MAX_DIMENSION;
const JAVA_MULTIPLIER: u64 = 0x5DEECE66D;
const JAVA_ADDEND: u64 = 0xB;
const JAVA_MASK: u64 = (1u64 << 48) - 1;

#[inline(never)] fn rounded_add(a: f32, b: f32) -> f32 { std::hint::black_box(a + b) }
#[inline(never)] fn rounded_sub(a: f32, b: f32) -> f32 { std::hint::black_box(a - b) }
#[inline(never)] fn rounded_mul(a: f32, b: f32) -> f32 { std::hint::black_box(a * b) }
#[inline(never)] fn rounded_div(a: f32, b: f32) -> f32 { std::hint::black_box(a / b) }

fn java_next(state: &mut u64, bits: u32) -> u32 {
    *state = state.wrapping_mul(JAVA_MULTIPLIER).wrapping_add(JAVA_ADDEND) & JAVA_MASK;
    (*state >> (48 - bits)) as u32
}

fn interpolate(a: f32, b: f32, alpha: f32) -> f32 {
    let one_minus_alpha = rounded_sub(1.0, alpha);
    let left = rounded_mul(a, one_minus_alpha);
    let right = rounded_mul(alpha, b);
    rounded_add(left, right)
}

fn exact_integer(value: f64, minimum: f64, maximum: f64) -> bool {
    value.is_finite() && value >= minimum && value <= maximum && value.trunc() == value
}

#[no_mangle]
pub unsafe extern "C" fn perlin_noise(input: *const f64, length: usize, output: *mut f64, output_capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_PARSEABLE_INPUT_ELEMENTS { return -1; }
    if length != MAX_INPUT_ELEMENTS { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !exact_integer(values[0], 1.0, 8.0) || !exact_integer(values[1], 1.0, 8.0) ||
       !exact_integer(values[2], 1.0, 4.0) || !exact_integer(values[4], 0.0, 2147483647.0) ||
       !(values[3] == 0.5 || values[3] == 0.75 || values[3] == 1.0) { return -1; }

    let width = values[0] as usize;
    let height = values[1] as usize;
    let octave_count = values[2] as usize;
    let seed = values[4] as u64;
    let count = width * height;
    let mut base = [0.0f32; MAX_OUTPUT_ELEMENTS];
    let mut layers = [0.0f32; 4 * MAX_OUTPUT_ELEMENTS];
    let mut result = [0.0f32; MAX_OUTPUT_ELEMENTS];

    let mut state = (seed ^ JAVA_MULTIPLIER) & JAVA_MASK;
    for x in 0..width { for y in 0..height {
        base[x * height + y] = rounded_div(java_next(&mut state, 24) as f32, 16777216.0);
    }}

    for octave in 0..octave_count {
        let period = 1usize << octave;
        let frequency = rounded_div(1.0, period as f32);
        let base_offset = octave * MAX_OUTPUT_ELEMENTS;
        for x in 0..width {
            let x0 = (x / period) * period;
            let x1 = (x0 + period) % width;
            let horizontal = rounded_mul((x - x0) as f32, frequency);
            for y in 0..height {
                let y0 = (y / period) * period;
                let y1 = (y0 + period) % height;
                let vertical = rounded_mul((y - y0) as f32, frequency);
                let top = interpolate(base[x0 * height + y0], base[x1 * height + y0], horizontal);
                let bottom = interpolate(base[x0 * height + y1], base[x1 * height + y1], horizontal);
                layers[base_offset + x * height + y] = interpolate(top, bottom, vertical);
            }
        }
    }

    let persistence = values[3] as f32;
    let mut amplitude = 1.0f32;
    let mut total_amplitude = 0.0f32;
    for octave in (0..octave_count).rev() {
        amplitude = rounded_mul(amplitude, persistence);
        total_amplitude = rounded_add(total_amplitude, amplitude);
        let base_offset = octave * MAX_OUTPUT_ELEMENTS;
        for i in 0..count {
            result[i] = rounded_add(result[i], rounded_mul(layers[base_offset + i], amplitude));
        }
    }
    let inverse_total = rounded_div(1.0, total_amplitude);
    for i in 0..count { result[i] = rounded_mul(result[i], inverse_total); }

    if output.is_null() || output_capacity < count { return -2; }
    for i in 0..count { *output.add(i) = result[i] as f64; }
    count as i64
}
