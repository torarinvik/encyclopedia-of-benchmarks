module damped_oscillator;

fn void put_f64_le(double value, char* output, usz offset) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long damped_oscillator(long* input, usz length, char* output, usz capacity) @export("damped_oscillator") {
    if (input == null || length != 5) return -1;
    if (input[0] < 1 || input[0] > 1024 || input[1] < 0 || input[1] > 1024 ||
        input[2] < -1024 || input[2] > 1024 || input[3] < -1024 || input[3] > 1024 ||
        input[4] < 1 || input[4] > 1024) return -1;
    if (output == null || capacity < 16) return -2;
    double omega0 = (double)input[0] / 1024.0;
    double gamma = (double)input[1] / 1024.0;
    double x = (double)input[2] / 1024.0;
    double v = (double)input[3] / 1024.0;
    double dt = (double)input[4] / 1024.0;
    double acceleration = -2.0 * gamma * v - omega0 * omega0 * x;
    double x_next = x + dt * v;
    double v_next = v + dt * acceleration;
    put_f64_le(x_next, output, 0);
    put_f64_le(v_next, output, 8);
    return 16;
}
