module dispersion;

const usz MAX_INPUT = 128;
const usz OUTPUT_BYTES = 16;
extern fn double sqrt(double value);

fn void put_f64_le(double value, char* output, usz offset) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long dispersion(long* values, usz length, char* output, usz capacity) @export("dispersion") {
    if (values == null || length == 0 || length > MAX_INPUT) return -1;
    for (usz i = 0; i < length; i++) if (values[i] < -10000 || values[i] > 10000) return -1;
    if (output == null || capacity < OUTPUT_BYTES) return -2;
    double sum = 0.0;
    for (usz i = 0; i < length; i++) sum += (double)values[i];
    double mean = sum / (double)length;
    double squared_deviations = 0.0;
    for (usz i = 0; i < length; i++) {
        double deviation = (double)values[i] - mean;
        squared_deviations += deviation * deviation;
    }
    double variance = squared_deviations / (double)length;
    put_f64_le(variance, output, 0);
    put_f64_le(sqrt(variance), output, 8);
    return (long)OUTPUT_BYTES;
}
