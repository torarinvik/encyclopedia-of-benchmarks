module polybench_adi;

const usz MAX_DIMENSION = 32;
const usz MAX_CELLS = MAX_DIMENSION * MAX_DIMENSION;
const long MAX_TSTEPS = 20;

fn void write_f64_le(char* output, usz offset, double value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long polybench_adi(long* values, usz length, char* output, usz output_capacity)
    @export("polybench_adi") {
    if (values == null || length != 2 || values[0] < 1 || values[0] > (long)MAX_DIMENSION ||
        values[1] < 1 || values[1] > MAX_TSTEPS) return -1;
    usz n = (usz)values[0];
    usz tsteps = (usz)values[1];
    usz cells = n * n;
    usz output_bytes = cells * 8;
    if (output == null || output_capacity < output_bytes) return -2;

    double[MAX_CELLS] u = zeroed;
    double[MAX_CELLS] v = zeroed;
    double[MAX_CELLS] p = zeroed;
    double[MAX_CELLS] q = zeroed;
    for (usz i = 0; i < n; i++)
        for (usz j = 0; j < n; j++)
            u[i * n + j] = (double)(i + n - j) / (double)n;

    double dx = 1.0 / (double)n;
    double dy = 1.0 / (double)n;
    double dt = 1.0 / (double)tsteps;
    double b1 = 2.0;
    double b2 = 1.0;
    double mul1 = b1 * dt / (dx * dx);
    double mul2 = b2 * dt / (dy * dy);
    double a = -mul1 / 2.0;
    double b = 1.0 + mul1;
    double c = a;
    double d = -mul2 / 2.0;
    double e = 1.0 + mul2;
    double f = d;

    for (usz t = 1; t <= tsteps; t++) {
        for (usz i = 1; i < n - 1; i++) {
            v[i] = 1.0;
            p[i * n] = 0.0;
            q[i * n] = v[i];
            for (usz j = 1; j < n - 1; j++) {
                p[i * n + j] = -c / (a * p[i * n + j - 1] + b);
                q[i * n + j] = (-d * u[j * n + i - 1] + (1.0 + 2.0 * d) * u[j * n + i]
                                - f * u[j * n + i + 1] - a * q[i * n + j - 1])
                               / (a * p[i * n + j - 1] + b);
            }
            v[(n - 1) * n + i] = 1.0;
            usz j = n - 1;
            while (j > 1) {
                j--;
                v[j * n + i] = p[i * n + j] * v[(j + 1) * n + i] + q[i * n + j];
            }
        }

        for (usz i = 1; i < n - 1; i++) {
            u[i * n] = 1.0;
            p[i * n] = 0.0;
            q[i * n] = u[i * n];
            for (usz j = 1; j < n - 1; j++) {
                p[i * n + j] = -f / (d * p[i * n + j - 1] + e);
                q[i * n + j] = (-a * v[(i - 1) * n + j] + (1.0 + 2.0 * a) * v[i * n + j]
                                - c * v[(i + 1) * n + j] - d * q[i * n + j - 1])
                               / (d * p[i * n + j - 1] + e);
            }
            u[i * n + n - 1] = 1.0;
            usz j = n - 1;
            while (j > 1) {
                j--;
                u[i * n + j] = p[i * n + j] * u[i * n + j + 1] + q[i * n + j];
            }
        }
    }

    for (usz index = 0; index < cells; index++) write_f64_le(output, index * 8, u[index]);
    return (long)output_bytes;
}
