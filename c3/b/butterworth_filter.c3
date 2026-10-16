module butterworth_filter;

extern fn double sin(double value);
extern fn double cos(double value);
extern fn double sqrt(double value);
extern fn double pow(double base, double exponent);
const double INVALID_RESULT = -1.0e300;

fn double butterworth_filter(long* values, usz length) @export("butterworth_filter") {
    if (values == null || length != 6) return INVALID_RESULT;
    long kind = values[0], coefficient_index = values[1];
    long frequency = values[2], samplerate = values[3];
    long gain_milli_db = values[4], q_micro = values[5];
    if (kind < 0 || kind > 8 || coefficient_index < 0 || coefficient_index > 5 ||
        frequency < 1 || frequency > 95999 || samplerate < 1 || samplerate > 192000 ||
        2 * frequency >= samplerate) return INVALID_RESULT;
    if (q_micro != -1 && (q_micro < 1 || q_micro > 10000000)) return INVALID_RESULT;
    bool needs_gain = kind >= 4 && kind <= 6;
    if (needs_gain) {
        if (gain_milli_db < -60000 || gain_milli_db > 60000) return INVALID_RESULT;
    } else if (gain_milli_db != 0) return INVALID_RESULT;

    double gain_db = needs_gain ? (double)gain_milli_db / 1000.0 : 0.0;
    double q_factor = q_micro == -1 ? 1.0 / sqrt(2.0) : (double)q_micro / 1000000.0;
    double w0 = 6.283185307179586476925286766559 * (double)frequency / (double)samplerate;
    double sine = sin(w0), cosine = cos(w0);
    double alpha = sine / (2.0 * q_factor);
    double a0 = 1.0 + alpha, a1 = -2.0 * cosine, a2 = 1.0 - alpha;
    double b0, b1, b2;
    if (kind == 0) {
        b0 = (1.0 - cosine) / 2.0; b1 = 1.0 - cosine; b2 = b0;
    } else if (kind == 1) {
        b0 = (1.0 + cosine) / 2.0; b1 = -1.0 - cosine; b2 = b0;
    } else if (kind == 2) {
        b0 = sine / 2.0; b1 = 0.0; b2 = -b0;
    } else if (kind == 3) {
        b0 = 1.0 - alpha; b1 = -2.0 * cosine; b2 = 1.0 + alpha;
        a0 = b2; a1 = b1; a2 = b0;
    } else if (kind == 4) {
        double big_a = pow(10.0, gain_db / 40.0);
        b0 = 1.0 + alpha * big_a; b1 = -2.0 * cosine; b2 = 1.0 - alpha * big_a;
        a0 = 1.0 + alpha / big_a; a1 = -2.0 * cosine; a2 = 1.0 - alpha / big_a;
    } else if (kind == 5 || kind == 6) {
        double big_a = pow(10.0, gain_db / 40.0);
        double pmc = (big_a + 1.0) - (big_a - 1.0) * cosine;
        double ppmc = (big_a + 1.0) + (big_a - 1.0) * cosine;
        double mpc = (big_a - 1.0) - (big_a + 1.0) * cosine;
        double pmpc = (big_a - 1.0) + (big_a + 1.0) * cosine;
        double aa2 = 2.0 * sqrt(big_a) * alpha;
        if (kind == 5) {
            b0 = big_a * (pmc + aa2); b1 = 2.0 * big_a * mpc; b2 = big_a * (pmc - aa2);
            a0 = ppmc + aa2; a1 = -2.0 * pmpc; a2 = ppmc - aa2;
        } else {
            b0 = big_a * (ppmc + aa2); b1 = -2.0 * big_a * pmpc; b2 = big_a * (ppmc - aa2);
            a0 = pmc + aa2; a1 = 2.0 * mpc; a2 = pmc - aa2;
        }
    } else if (kind == 7) {
        b0 = 1.0; b1 = -2.0 * cosine; b2 = 1.0;
    } else {
        b0 = alpha; b1 = 0.0; b2 = -alpha;
    }
    double output[6] = {a0, a1, a2, b0, b1, b2};
    return output[coefficient_index];
}
