module ode_semi_implicit_euler;

fn void store_f64_le(char* output, usz offset, double value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long ode_semi_implicit_euler(long* values, usz length, char* output, usz output_capacity)
        @export("ode_semi_implicit_euler") {
    if (values == null || length != 4) return -1;
    if (values[0] < 1 || values[0] > 8 || values[1] < 1 || values[1] > 4 ||
        values[2] < -10 || values[2] > 10 || values[3] < -10 || values[3] > 10) return -1;
    if (output == null || output_capacity < 16) return -2;
    double dt = (double)values[1] / 4.0;
    double u = (double)values[2], v = (double)values[3];
    for (long step = 0; step < values[0]; step++) {
        double old_u = u, old_v = v;
        u = old_u + dt * old_v;
        v = old_v - dt * u;
    }
    store_f64_le(output, 0, u);
    store_f64_le(output, 8, v);
    return 16;
}
