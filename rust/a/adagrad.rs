const MAX_STEPS: usize = 256;
const MAX_GROUPS: usize = 16;
const INPUT_SCALE: f64 = 1_000_000_000.0;
const OUTPUT_SCALE: f64 = 1_000_000.0;

fn adagrad_sqrt(value: f64) -> f64 {
    if value <= 0.0 { return 0.0; }
    let mut root = if value > 1.0 { value } else { 1.0 };
    for _ in 0..80 { root = 0.5 * (root + value / root); }
    root
}

#[no_mangle]
pub unsafe extern "C" fn adagrad(input: *const i64, length: usize,
                                  output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 6 || length > 3 + 3 * MAX_STEPS { return -1; }
    let steps_value = *input;
    let learning_rate_value = *input.add(1);
    let epsilon_value = *input.add(2);
    if steps_value < 1 || steps_value > MAX_STEPS as i64 ||
        length != 3 + 3 * steps_value as usize ||
        learning_rate_value < 1 || learning_rate_value > 1_000_000_000 ||
        epsilon_value < 1 || epsilon_value > 10_000_000 { return -1; }
    let steps = steps_value as usize;
    for step in 0..steps {
        let id = *input.add(3 + 3 * step);
        let parameter = *input.add(4 + 3 * step);
        let gradient = *input.add(5 + 3 * step);
        if id < 0 || id >= MAX_GROUPS as i64 ||
            !(-1_000_000_000_000_000..=1_000_000_000_000_000).contains(&parameter) ||
            !(-1_000_000_000_000..=1_000_000_000_000).contains(&gradient) { return -1; }
    }
    if output.is_null() || output_capacity < 8 * steps { return -2; }

    let learning_rate = learning_rate_value as f64 / INPUT_SCALE;
    let epsilon = epsilon_value as f64 / INPUT_SCALE;
    let mut accumulated = [0.0f64; MAX_GROUPS];
    for step in 0..steps {
        let id = *input.add(3 + 3 * step) as usize;
        let parameter = *input.add(4 + 3 * step) as f64 / INPUT_SCALE;
        let gradient = *input.add(5 + 3 * step) as f64 / INPUT_SCALE;
        accumulated[id] += gradient * gradient;
        let updated = parameter - learning_rate / (adagrad_sqrt(accumulated[id]) + epsilon) * gradient;
        let encoded = (updated * OUTPUT_SCALE) as i64 as u64;
        for byte in 0..8 { *output.add(8 * step + byte) = (encoded >> (8 * byte)) as u8; }
    }
    steps as i64
}
