module syrk;

const int MAX_N = 8;
const int MAX_M = 16;

fn bool dimension_value(double value, int maximum) {
    if (value != value || value < 1.0 || value > (double)maximum) return false;
    return (double)(int)value == value;
}

fn long syrk(double* input, usz length, double* output, usz capacity) @export("syrk") {
    if (input == null || length != 2 || !dimension_value(input[0], MAX_N) ||
        !dimension_value(input[1], MAX_M)) return -1;
    int n = (int)input[0];
    int m = (int)input[1];
    double alpha = 1.5;
    double beta = 1.2;
    double[128] a;
    double[64] c;

    for (int i = 0; i < n; i++)
        for (int k = 0; k < m; k++)
            a[i * m + k] = (double)((i * k + 1) % n) / (double)n;
    for (int i = 0; i < n; i++)
        for (int j = 0; j < n; j++)
            c[i * n + j] = (double)((i * j + 2) % m) / (double)m;

    for (int i = 0; i < n; i++) {
        for (int j = 0; j <= i; j++) c[i * n + j] *= beta;
        for (int k = 0; k < m; k++)
            for (int j = 0; j <= i; j++)
                c[i * n + j] += alpha * a[i * m + k] * a[j * m + k];
    }

    usz required = (usz)(n * n);
    if (output == null || capacity < required) return -2;
    for (usz index = 0; index < required; index++) output[index] = c[index];
    return (long)required;
}
