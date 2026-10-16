const MIN_X_NANOUNITS: i64 = -6300000000;
const MAX_X_NANOUNITS: i64 = 6300000000;
const DEFAULT_STEP: f64 = 1.0e-10;
const INVALID_RESULT: f64 = -1.0e300;

export fn symmetric_derivative(values: ?[*]const i64, length: usize) f64 {
    if (values == null or length != 2) return INVALID_RESULT;
    const input = values.?;
    const function_id = input[0];
    const x_nanounits = input[1];
    if ((function_id != 0 and function_id != 1) or
        x_nanounits < MIN_X_NANOUNITS or x_nanounits > MAX_X_NANOUNITS) return INVALID_RESULT;

    const x = @as(f64, @floatFromInt(x_nanounits)) / 1000000000.0;
    const upper = if (function_id == 0) @sin(x + DEFAULT_STEP) else @exp(x + DEFAULT_STEP);
    const lower = if (function_id == 0) @sin(x - DEFAULT_STEP) else @exp(x - DEFAULT_STEP);
    return (upper - lower) / (2.0 * DEFAULT_STEP);
}
