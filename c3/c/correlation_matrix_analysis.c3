module correlation_matrix_analysis;

extern fn double sqrt(double value);
const usz MAX_P = 5;
const usz MAX_PAIRS = 10;

fn void put_f64(double value, char* output, usz offset) {
    ulong bits = @bitcast(ulong, value);
    for (usz b = 0; b < 8; b++) { output[offset + b] = (char)(bits & 255); bits >>= 8; }
}
fn void put_i64(long value, char* output, usz offset) {
    ulong bits = @bitcast(ulong, value);
    for (usz b = 0; b < 8; b++) { output[offset + b] = (char)(bits & 255); bits >>= 8; }
}

fn long correlation_matrix_analysis(long* input, usz length, char* output, usz capacity) @export("correlation_matrix_analysis") {
    if (input == null || length < 2 || length > 22 || input[0] != 4 || input[1] < 2 || input[1] > 5) return -1;
    usz p = (usz)input[1];
    if (length != 2 + 4 * p) return -1;
    for (usz i = 0; i < 4 * p; i++) if (input[2 + i] < -1000 || input[2 + i] > 1000) return -1;
    for (usz col = 0; col < p; col++) {
        bool varying = false;
        for (usz row = 1; row < 4; row++) if (input[2 + row * p + col] != input[2 + col]) varying = true;
        if (!varying) return -1;
    }
    usz output_bytes = 32 * p * p + 48;
    if (output == null || capacity < output_bytes) return -2;
    double[5] means = zeroed;
    for (usz col = 0; col < p; col++) {
        for (usz row = 0; row < 4; row++) means[col] += (double)input[2 + row * p + col];
        means[col] /= 4.0;
    }
    double[25] corr = zeroed;
    double[25] raw = zeroed;
    double[25] bonf = zeroed;
    double[25] fdr = zeroed;
    for (usz i = 0; i < 25; i++) { raw[i] = 1.0; bonf[i] = 1.0; fdr[i] = 1.0; }
    for (usz i = 0; i < p; i++) corr[i * p + i] = 1.0;
    usz[MAX_PAIRS] pair_i = {};
    usz[MAX_PAIRS] pair_j = {};
    double[MAX_PAIRS] pair_p = {};
    usz pair_count = 0;
    for (usz j = 1; j < p; j++) for (usz i = 0; i < j; i++) {
        double cross = 0.0;
        double sum_i = 0.0;
        double sum_j = 0.0;
        for (usz row = 0; row < 4; row++) {
            double dx = (double)input[2 + row * p + i] - means[i];
            double dy = (double)input[2 + row * p + j] - means[j];
            cross += dx * dy;
            sum_i += dx * dx;
            sum_j += dy * dy;
        }
        double r = cross / sqrt(sum_i * sum_j);
        double abs_r = r < 0.0 ? -r : r;
        double pv = 1.0 - abs_r;
        corr[i * p + j] = r; corr[j * p + i] = r;
        raw[i * p + j] = pv; raw[j * p + i] = pv;
        pair_i[pair_count] = i; pair_j[pair_count] = j; pair_p[pair_count] = pv; pair_count++;
    }
    for (usz k = 0; k < pair_count; k++) {
        double adjusted = pair_p[k] * (double)pair_count;
        if (adjusted > 1.0) adjusted = 1.0;
        usz i = pair_i[k]; usz j = pair_j[k];
        bonf[i * p + j] = adjusted; bonf[j * p + i] = adjusted;
    }
    usz[MAX_PAIRS] order = {};
    for (usz k = 0; k < pair_count; k++) order[k] = k;
    for (usz k = 1; k < pair_count; k++) {
        usz value = order[k]; usz at = k;
        while (at > 0 && pair_p[order[at - 1]] > pair_p[value]) { order[at] = order[at - 1]; at--; }
        order[at] = value;
    }
    double running = 1.0;
    usz pos = pair_count;
    while (pos > 0) {
        pos--;
        double adjusted = pair_p[order[pos]] * (double)pair_count / (double)(pos + 1);
        if (adjusted > 1.0) adjusted = 1.0;
        if (adjusted < running) running = adjusted;
        usz k = order[pos]; usz i = pair_i[k]; usz j = pair_j[k];
        fdr[i * p + j] = running; fdr[j * p + i] = running;
    }
    long sig_raw = 0; long sig_bonf = 0; long sig_fdr = 0;
    for (usz k = 0; k < pair_count; k++) {
        usz index = pair_i[k] * p + pair_j[k];
        if (pair_p[k] < 0.05) sig_raw++;
        if (bonf[index] < 0.05) sig_bonf++;
        if (fdr[index] < 0.05) sig_fdr++;
    }
    usz offset = 0;
    for (usz i = 0; i < p * p; i++) { put_f64(corr[i], output, offset); offset += 8; }
    for (usz i = 0; i < p * p; i++) { put_f64(raw[i], output, offset); offset += 8; }
    for (usz i = 0; i < p * p; i++) { put_f64(bonf[i], output, offset); offset += 8; }
    for (usz i = 0; i < p * p; i++) { put_f64(fdr[i], output, offset); offset += 8; }
    long[6] summary = {4, (long)p, 0, sig_raw, sig_bonf, sig_fdr};
    for (usz i = 0; i < 6; i++) { put_i64(summary[i], output, offset); offset += 8; }
    return (long)offset;
}
