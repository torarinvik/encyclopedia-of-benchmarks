const std = @import("std");

const SCALE: i64 = 1_000_000;
const MAX_ENDPOINT_MICRO: i64 = 1_000_000;
const MAX_STEPS: i64 = 10_000;
const INVALID_RESULT: f64 = -1.0e300;

fn sampleValue(function_id: i64, x: f64) f64 {
    if (function_id == 0) return x * x;
    return x * x * x;
}

export fn trapezoidal_integration(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 4) return INVALID_RESULT;
    const start_micro = values[0];
    const end_micro = values[1];
    const steps = values[2];
    const function_id = values[3];
    if (start_micro < -MAX_ENDPOINT_MICRO or start_micro > MAX_ENDPOINT_MICRO or
        end_micro < -MAX_ENDPOINT_MICRO or end_micro > MAX_ENDPOINT_MICRO or
        steps < 1 or steps > MAX_STEPS or function_id < 0 or function_id > 1) return INVALID_RESULT;

    const start = @as(f64, @floatFromInt(start_micro)) / @as(f64, @floatFromInt(SCALE));
    const end = @as(f64, @floatFromInt(end_micro)) / @as(f64, @floatFromInt(SCALE));
    const delta = (end - start) / @as(f64, @floatFromInt(steps));
    var total: f64 = 0.0;
    var index: i64 = 0;
    while (index < steps) : (index += 1) {
        const left = start + delta * @as(f64, @floatFromInt(index));
        const right = left + delta;
        const midpoint = (sampleValue(function_id, left) + sampleValue(function_id, right)) * 0.5;
        total += midpoint * delta;
    }
    return total;
}
