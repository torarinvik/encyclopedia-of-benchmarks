const MAX_LENGTH: usize = 64;
const ITERATIONS: usize = 100;
const LEARNING_RATE: f64 = 0.01;
const BETA: f64 = 0.9;

export fn momentum(input: [*c]const f64, length: usize,
    output: [*c]f64, output_capacity: usize) i64 {
    if (input == null or length == 0 or length > MAX_LENGTH) return -1;
    var values: [MAX_LENGTH]f64 = undefined;
    var velocity: [MAX_LENGTH]f64 = [_]f64{0.0} ** MAX_LENGTH;
    var gradient: [MAX_LENGTH]f64 = undefined;
    for (0..length) |index| {
        const value = input[index];
        if (value != value or value < -1000000.0 or value > 1000000.0) return -1;
        values[index] = value;
    }
    if (output == null or output_capacity < length) return -2;

    for (0..ITERATIONS) |_| {
        for (0..length) |index| gradient[index] = 2.0 * values[index];
        for (0..length) |index| {
            velocity[index] = BETA * velocity[index] + gradient[index];
            values[index] -= LEARNING_RATE * velocity[index];
        }
    }
    for (0..length) |index| output[index] = values[index];
    return @intCast(length);
}
