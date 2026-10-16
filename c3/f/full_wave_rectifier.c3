module full_wave_rectifier;

const long OUTPUT_BYTES = 48;

fn void store_f64_le(char* output, usz offset, double value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255ul);
        bits >>= 8;
    }
}

// Evaluate the six pinned full-wave rectifier helper formulas.
fn long full_wave_rectifier(long* values, usz length, char* output, usz output_capacity)
        @export("full_wave_rectifier") {
    if (values == null || length != 5) return -1;
    long rf_i = values[0], rs_i = values[1], rl_i = values[2];
    long vm_i = values[3], im_i = values[4];
    if (rf_i < 0 || rf_i > 1000000 || rs_i < 0 || rs_i > 1000000 ||
        rl_i < 1 || rl_i > 1000000 || vm_i < -1000000 || vm_i > 1000000 ||
        im_i < -1000000 || im_i > 1000000) return -1;
    if (output == null || output_capacity < 48) return -2;

    double rf = (double)rf_i, rs = (double)rs_i, rl = (double)rl_i;
    double vm = (double)vm_i, im = (double)im_i;
    store_f64_le(output, 0, vm / (rf + rs + rl));
    store_f64_le(output, 8, 2.0 * im * 0.318);
    store_f64_le(output, 16, 2.0 * 0.318 * vm);
    store_f64_le(output, 24, vm / rl);
    store_f64_le(output, 32, im * 0.707);
    store_f64_le(output, 40, vm * 0.707);
    return 48;
}
