const std = @import("std");
const PI: f64 = 3.14159265358979323846;

fn roundedSix(value: f64) f64 { return @round(value * 1_000_000.0) / 1_000_000.0; }

fn integerPower(value: f64, exponent: i32) f64 {
    var result: f64 = 1.0;
    for (0..@intCast(exponent)) |_| result *= value;
    return result;
}

fn factorialDouble(n: i32) f64 {
    var result: f64 = 1.0;
    if (n > 1) for (2..@as(usize, @intCast(n)) + 1) |factor| { result *= @floatFromInt(factor); };
    return result;
}

fn trigSeries(input_value: f64, tolerance: f64, kind: i32) f64 {
    var value = input_value;
    const period = 2.0 * PI;
    while (value >= period) value -= period;
    while (value <= -period) value += period;
    var result: f64 = 0.0;
    var previous: f64 = 1.0;
    var step: i32 = 0;
    while (@abs(previous - result) > tolerance) : (step += 1) {
        previous = result;
        const power = 2 * step + kind;
        const term = integerPower(value, power) / factorialDouble(power);
        result += if (@mod(step, 2) == 0) term else -term;
    }
    return roundedSix(result);
}

export fn trig_functions(input: [*c]const f64, length: usize, output: [*c]f64, capacity: usize) i64 {
    if (input == null or length != 3) return -1;
    const selector_value = input[0];
    var x = input[1];
    const tolerance = input[2];
    if (!std.math.isFinite(selector_value) or selector_value < 0 or selector_value > 7 or @floor(selector_value) != selector_value) return -1;
    if (!std.math.isFinite(tolerance) or tolerance < 1e-9 or tolerance > 1e-2) return -1;
    if (std.math.isFinite(x) and (x < -10000 or x > 10000)) return -1;
    if (output == null or capacity < 1) return -2;
    if (!std.math.isFinite(x)) { output[0] = std.math.nan(f64); return 1; }

    const selector: i32 = @intFromFloat(selector_value);
    if (selector == 2 or selector == 3 or selector == 6 or selector == 7) x = x * PI / 180.0;
    var result: f64 = 0.0;
    if (selector == 0 or selector == 2) result = trigSeries(x, tolerance, 1)
    else if (selector == 1 or selector == 3) result = trigSeries(x, tolerance, 0)
    else if (selector == 4 or selector == 6) {
        const denominator = trigSeries(x, tolerance, 0);
        result = if (denominator == 0.0) std.math.nan(f64) else trigSeries(x, tolerance, 1) / denominator;
    } else {
        const denominator = trigSeries(x, tolerance, 1);
        result = if (denominator == 0.0) std.math.nan(f64) else trigSeries(x, tolerance, 0) / denominator;
    }
    output[0] = result;
    return 1;
}
