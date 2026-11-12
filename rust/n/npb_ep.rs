const MAX_PAIRS: usize = 4096;
const MODULUS_MASK: u64 = 70_368_744_177_663;
const WORD_MASK: u64 = 8_388_607;
const MULTIPLIER: u64 = 1_220_703_125;
const MODULUS_SCALE: f64 = 70_368_744_177_664.0;

fn is_bounded_integer(value: f64, minimum: f64, maximum: f64) -> bool {
    value.is_finite() && value.fract() == 0.0 && value >= minimum && value <= maximum
}

fn advance_state(state: u64) -> u64 {
    let low = state & WORD_MASK;
    let high = state >> 23;
    let multiplier_low = MULTIPLIER & WORD_MASK;
    let multiplier_high = MULTIPLIER >> 23;
    let low_product = low * multiplier_low;
    let cross = (low * multiplier_high + high * multiplier_low) & WORD_MASK;
    (low_product + (cross << 23)) & MODULUS_MASK
}

#[no_mangle]
pub unsafe extern "C" fn npb_ep(
    input: *const f64,
    length: usize,
    output: *mut f64,
    capacity: usize,
) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let pair_count_value = *input;
    let seed_value = *input.add(1);
    if !is_bounded_integer(pair_count_value, 1.0, MAX_PAIRS as f64)
        || !is_bounded_integer(seed_value, 1.0, 70_368_744_177_663.0)
    { return -1; }
    let pair_count = pair_count_value as usize;
    if output.is_null() || capacity < 12 { return -2; }

    let mut state = seed_value as u64;
    let mut histogram = [0_u64; 10];
    let mut sum_x = 0.0;
    let mut sum_y = 0.0;
    for _ in 0..pair_count {
        state = advance_state(state);
        let x = 2.0 * (state as f64 / MODULUS_SCALE) - 1.0;
        state = advance_state(state);
        let y = 2.0 * (state as f64 / MODULUS_SCALE) - 1.0;
        let radius_squared = x * x + y * y;
        if radius_squared <= 0.0 || radius_squared > 1.0 { continue; }
        let scale = (-2.0 * radius_squared.ln() / radius_squared).sqrt();
        let normal_x = x * scale;
        let normal_y = y * scale;
        let extent = normal_x.abs().max(normal_y.abs());
        if extent < 10.0 { histogram[extent as usize] += 1; }
        sum_x += normal_x;
        sum_y += normal_y;
    }
    for (index, count) in histogram.iter().enumerate() {
        *output.add(index) = *count as f64;
    }
    *output.add(10) = sum_x;
    *output.add(11) = sum_y;
    12
}
