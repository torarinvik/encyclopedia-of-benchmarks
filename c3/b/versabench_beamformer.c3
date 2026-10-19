module versabench_beamformer;
const usz CHANNELS = 12;
fn long versabench_beamformer(double* input, usz length, double* output, usz capacity) @export("versabench_beamformer") {
    if (input == null || length != 48) { return -1; }
    float[48] values;
    for (usz i = 0; i < 48; i++) {
        double x = input[i];
        if (x != x || x < -128.0 || x > 128.0) { return -1; }
        values[i] = (float)x;
    }
    float real = 0.0, imag = 0.0;
    for (usz c = 0; c < CHANNELS; c++) {
        usz b = 4 * c;
        float rr = values[b] * values[b + 2] - values[b + 1] * values[b + 3];
        float ii = values[b] * values[b + 3] + values[b + 1] * values[b + 2];
        real = real + rr;
        imag = imag + ii;
    }
    if (output == null || capacity < 2) { return -2; }
    output[0] = (double)real; output[1] = (double)imag; return 2;
}
