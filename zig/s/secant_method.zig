const std = @import("std");
const INVALID_RESULT: f64 = -1.0e300;

fn pythonObjective(x: f64) f64 {
    return 8.0 * x - 2.0 * @exp(-x);
}

fn cVariant() f64 {
    var x0: f64 = 0.2;
    var x1: f64 = 0.5;
    const tolerance = 100.0 / 1000000.0;
    for (0..99) |_| {
        const f1 = x1 * x1 - 3.0;
        const f0 = x0 * x0 - 3.0;
        const x2 = x1 - f1 * (x1 - x0) / (f1 - f0);
        x0 = x1;
        x1 = x2;
        if (@abs(x1 - x0) < tolerance) return x2;
    }
    return -1.0;
}

fn pythonVariant(repeats: i64) f64 {
    var x0: f64 = 1.0;
    var x1: f64 = 3.0;
    for (0..@as(usize, @intCast(repeats))) |_| {
        const f1 = pythonObjective(x1);
        const f0 = pythonObjective(x0);
        const x2 = x1 - (f1 * (x1 - x0)) / (f1 - f0);
        x0 = x1;
        x1 = x2;
    }
    return x1;
}

export fn secant_method(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 2) return INVALID_RESULT;
    const variant = values[0];
    const control = values[1];
    if (variant == 0 and control == 100) return cVariant();
    if (variant == 1 and control >= 0 and control <= 2) return pythonVariant(control);
    return INVALID_RESULT;
}
