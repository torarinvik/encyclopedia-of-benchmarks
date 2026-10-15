/// Three reciprocal thin-lens formula solves.
export fn lens_formulae(values: [*]const i64, length: usize) f64 {
    if (length != 3) return -1.0e300;
    const operation = values[0];
    const first = values[1];
    const second = values[2];
    if (operation < 0 or operation > 2 or first == 0 or second == 0 or first < -1_000_000 or
        first > 1_000_000 or second < -1_000_000 or second > 1_000_000) return -1.0e300;
    if (operation == 0) {
        if (first == second) return -1.0e300;
        return 1.0 / ((1.0 / @as(f64, @floatFromInt(second))) - (1.0 / @as(f64, @floatFromInt(first))));
    }
    if (operation == 1) {
        if (first == second) return -1.0e300;
        return 1.0 / ((1.0 / @as(f64, @floatFromInt(second))) - (1.0 / @as(f64, @floatFromInt(first))));
    }
    if (first == -second) return -1.0e300;
    return 1.0 / ((1.0 / @as(f64, @floatFromInt(second))) + (1.0 / @as(f64, @floatFromInt(first))));
}
