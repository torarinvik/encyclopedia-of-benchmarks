const MAX_INPUT_LENGTH: usize = 6;
const INVALID_RESULT: f64 = -1.0e300;

fn objective(operation: i64, x: f64) f64 {
    const delta = if (operation == 0) x - 1.0 else x + 1.0;
    const square = delta * delta;
    return if (operation == 0) -square else square;
}

fn ternarySearch(operation: i64, a: f64, b: f64, epsilon: f64,
                 frame: i64, max_calls: i64) f64 {
    if (@abs(a - b) <= epsilon) return objective(operation, (a + b) / 2.0);

    const left = (2.0 * a + b) / 3.0;
    const right = (a + 2.0 * b) / 3.0;
    const left_value = objective(operation, left);
    const right_value = objective(operation, right);
    const take_left = if (operation == 0) left_value < right_value else left_value > right_value;
    if (frame >= max_calls) return INVALID_RESULT;
    if (take_left) return ternarySearch(operation, left, b, epsilon, frame + 1, max_calls);
    return ternarySearch(operation, a, right, epsilon, frame + 1, max_calls);
}

export fn ternary(input: ?[*]const i64, length: usize) f64 {
    if (input == null or length < 5 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const values = input.?[0..length];
    const operation = values[0];
    const a_milli = values[1];
    const b_milli = values[2];
    const epsilon_micro = values[3];
    const max_calls = values[4];
    if (length != 5 or (operation != 0 and operation != 1) or
        a_milli < -1_000_000 or a_milli > b_milli or b_milli > 1_000_000 or
        epsilon_micro < 1 or epsilon_micro > 1_000_000 or max_calls < 1 or max_calls > 64)
        return INVALID_RESULT;

    return ternarySearch(operation, @as(f64, @floatFromInt(a_milli)) / 1000.0,
                         @as(f64, @floatFromInt(b_milli)) / 1000.0,
                         @as(f64, @floatFromInt(epsilon_micro)) / 1_000_000.0, 1, max_calls);
}
