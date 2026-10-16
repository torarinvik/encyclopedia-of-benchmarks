module gauss_optimization;

fn double objective(double x1, double x2, double target1, double target2) {
    double dx = x1 - target1;
    double dy = x2 - target2;
    return -(dx * dx + dy * dy);
}

fn double magnitude(double value) { return value < 0.0 ? -value : value; }

fn long gauss_optimization(double* values, usz length, double* output, usz capacity) @export("gauss_optimization") {
    if (values == null || length != 7) return -1;
    for (usz i = 0; i < length; i++) if (values[i] != values[i] || values[i] > 1.0e100 || values[i] < -1.0e100) return -1;
    if ((values[0] != 2.0 && values[0] != 3.0 && values[0] != 4.0) ||
        values[1] < 0.25 || values[1] > 4.0 || values[2] < 1.0e-6 || values[2] > 2.0) return -1;
    for (usz i = 3; i < 7; i++) if (values[i] < -8.0 || values[i] > 8.0) return -1;
    if (output == null || capacity < 2) return -2;

    double factor = values[0];
    double step = values[1];
    double epsilon = values[2];
    double x1 = values[3];
    double x2 = values[4];
    double target1 = values[5];
    double target2 = values[6];
    double error = 1.0;
    usz iteration = 0;
    while (magnitude(error) > epsilon && iteration < 256) {
        double current = objective(x1, x2, target1, target2);
        double best = objective(x1, x2 - step, target1, target2);
        int choice = 0;
        double candidate = objective(x1, x2 + step, target1, target2);
        if (candidate > best) { best = candidate; choice = 1; }
        candidate = objective(x1 - step, x2, target1, target2);
        if (candidate > best) { best = candidate; choice = 2; }
        candidate = objective(x1 + step, x2, target1, target2);
        if (candidate > best) { best = candidate; choice = 3; }
        error = best - current;
        if (choice == 0) { x2 -= step; }
        else if (choice == 1) { x2 += step; }
        else if (choice == 2) { x1 -= step; }
        else { x1 += step; }
        step /= factor;
        iteration++;
    }
    if (magnitude(error) > epsilon) return -1;
    output[0] = x1;
    output[1] = x2;
    return 2;
}
