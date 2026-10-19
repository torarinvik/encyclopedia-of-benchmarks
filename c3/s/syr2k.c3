module syr2k;

const int MAX_N = 8;
const int MAX_M = 16;

fn bool dimension_value(double value, int maximum) {
    if (value != value || value < 1.0 || value > (double)maximum) return false;
    return (double)(int)value == value;
}

fn long syr2k(double* input, usz length, double* output, usz capacity) @export("syr2k") {
    if (input == null || length != 2 || !dimension_value(input[0], MAX_N) ||
        !dimension_value(input[1], MAX_M)) return -1;
    int n = (int)input[0];
    int m = (int)input[1];
    double alpha = 1.5;
    double beta = 1.2;
    double[128] a;
    double[128] b;
    double[64] c;

    for (int i = 0; i < n; i++)
        for (int j = 0; j < m; j++) {
            a[i * m + j] = (double)((i * j + 1) % n) / (double)n;
            b[i * m + j] = (double)((i * j + 2) % m) / (double)m;
        }
    for (int i = 0; i < n; i++)
        for (int j = 0; j < n; j++)
            c[i * n + j] = (double)((i * j + 3) % n) / (double)m;

    for (int i = 0; i < n; i++) {
        for (int j = 0; j <= i; j++) c[i * n + j] *= beta;
        for (int k = 0; k < m; k++)
            for (int j = 0; j <= i; j++)
                c[i * n + j] += a[j * m + k] * alpha * b[i * m + k]
                              + b[j * m + k] * alpha * a[i * m + k];
    }

    usz required = (usz)(n * n);
    if (output == null || capacity < required) return -2;
    for (usz index = 0; index < required; index++) output[index] = c[index];
    return (long)required;
}
