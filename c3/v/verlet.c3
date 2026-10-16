module verlet;

extern fn double floor(double value);

fn long verlet(double* values, usz length, double* output, usz capacity) @export("verlet") {
    if (values == null || length != 4) return -1;
    for (usz i = 0; i < length; i++) if (values[i] != values[i] || values[i] > 1.0e100 || values[i] < -1.0e100) return -1;
    if (values[0] < 2.0 || values[0] > 32.0 || floor(values[0]) != values[0] ||
        values[1] < -1.0 || values[1] > 1.0 ||
        values[2] < -1.0 || values[2] > 1.0 ||
        values[3] < 0.0 || values[3] > 4.0 || floor(values[3]) != values[3]) return -1;

    usz n = (usz)values[0];
    int code = (int)values[3];
    double dt = 0.00390625;
    if (code == 1) dt = 0.0078125;
    else if (code == 2) dt = 0.015625;
    else if (code == 3) dt = 0.03125;
    else if (code == 4) dt = 0.0625;
    double dt_squared = dt * dt;
    if (output == null || capacity < 2 * n) return -2;

    output[0] = values[1];
    output[1] = values[1] + values[2] * dt + 0.5 * (-values[1]) * dt_squared;
    for (usz i = 1; i < n - 1; i++) output[i + 1] = 2.0 * output[i] - output[i - 1] + (-output[i]) * dt_squared;
    for (usz i = 0; i < n; i++) output[n + i] = (double)i * dt;
    return (long)(2 * n);
}
