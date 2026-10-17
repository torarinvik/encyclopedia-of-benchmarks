const MAX_LENGTH: usize = 64;
const ITERATIONS: usize = 100;
const LEARNING_RATE: f64 = 0.01;
const BETA: f64 = 0.9;

#[no_mangle]
pub unsafe extern "C" fn momentum(input: *const f64, length: usize,
    output: *mut f64, output_capacity: usize) -> i64 {
    if input.is_null() || length == 0 || length > MAX_LENGTH { return -1; }
    let mut values = [0.0_f64; MAX_LENGTH];
    let mut velocity = [0.0_f64; MAX_LENGTH];
    let mut gradient = [0.0_f64; MAX_LENGTH];
    for index in 0..length {
        let value = *input.add(index);
        if !value.is_finite() || value < -1_000_000.0 || value > 1_000_000.0 { return -1; }
        values[index] = value;
    }
    if output.is_null() || output_capacity < length { return -2; }

    for _ in 0..ITERATIONS {
        for index in 0..length { gradient[index] = 2.0 * values[index]; }
        for index in 0..length {
            velocity[index] = BETA * velocity[index] + gradient[index];
            values[index] -= LEARNING_RATE * velocity[index];
        }
    }
    for index in 0..length { *output.add(index) = values[index]; }
    length as i64
}
