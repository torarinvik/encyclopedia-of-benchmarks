fn objective(x1: f64, x2: f64, target1: f64, target2: f64) f64 {
    const dx = x1 - target1;
    const dy = x2 - target2;
    return -(dx * dx + dy * dy);
}

export fn gauss_optimization(values: [*c]const f64, length: usize, output: [*c]f64, capacity: usize) i64 {
    if (values == null or length != 7) return -1;
    for (0..7) |i| {
        if (values[i] != values[i] or values[i] > 1.0e100 or values[i] < -1.0e100) return -1;
    }
    if ((values[0] != 2.0 and values[0] != 3.0 and values[0] != 4.0) or
        values[1] < 0.25 or values[1] > 4.0 or values[2] < 1.0e-6 or values[2] > 2.0) return -1;
    for (3..7) |i| if (values[i] < -8.0 or values[i] > 8.0) return -1;
    if (output == null or capacity < 2) return -2;

    const factor = values[0];
    var step = values[1];
    const epsilon = values[2];
    var x1 = values[3];
    var x2 = values[4];
    const target1 = values[5];
    const target2 = values[6];
    var delta: f64 = 1.0;
    var iteration: usize = 0;
    while (@abs(delta) > epsilon and iteration < 256) : (iteration += 1) {
        const current = objective(x1, x2, target1, target2);
        var best = objective(x1, x2 - step, target1, target2);
        var choice: usize = 0;
        var candidate = objective(x1, x2 + step, target1, target2);
        if (candidate > best) { best = candidate; choice = 1; }
        candidate = objective(x1 - step, x2, target1, target2);
        if (candidate > best) { best = candidate; choice = 2; }
        candidate = objective(x1 + step, x2, target1, target2);
        if (candidate > best) { best = candidate; choice = 3; }
        delta = best - current;
        if (choice == 0) x2 -= step
        else if (choice == 1) x2 += step
        else if (choice == 2) x1 -= step
        else x1 += step;
        step /= factor;
    }
    if (@abs(delta) > epsilon) return -1;
    output[0] = x1;
    output[1] = x2;
    return 2;
}
