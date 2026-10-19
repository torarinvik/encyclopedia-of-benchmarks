module polybench_ludcmp;

const usz MAX_DIMENSION = 64;
const usz MAX_CELLS = MAX_DIMENSION * MAX_DIMENSION;
const double INVALID_RESULT = -1e300;

fn double polybench_ludcmp(long* values, ulong length) @export("polybench_ludcmp") {
    if (values == null || length != 1 || values[0] < 1 || values[0] > (long)MAX_DIMENSION)
        return INVALID_RESULT;
    usz n = (usz)values[0];
    double[MAX_CELLS] a = {};
    double[MAX_CELLS] product = {};
    double[MAX_DIMENSION] b = {};
    double[MAX_DIMENSION] x = {};
    double[MAX_DIMENSION] y = {};
    for (usz i = 0; i < n; i++) {
        x[i] = 0.0;
        y[i] = 0.0;
        b[i] = ((double)(i + 1) / (double)n) / 2.0 + 4.0;
    }
    for (usz i = 0; i < n; i++) {
        for (usz j = 0; j <= i; j++) a[i * n + j] = (double)(-(long)j % (long)n) / (double)n + 1.0;
        for (usz j = i + 1; j < n; j++) a[i * n + j] = 0.0;
        a[i * n + i] = 1.0;
    }
    for (usz r = 0; r < n; r++)
        for (usz s = 0; s < n; s++) product[r * n + s] = 0.0;
    for (usz t = 0; t < n; t++)
        for (usz r = 0; r < n; r++)
            for (usz s = 0; s < n; s++)
                product[r * n + s] = product[r * n + s] + a[r * n + t] * a[s * n + t];
    for (usz r = 0; r < n; r++)
        for (usz s = 0; s < n; s++) a[r * n + s] = product[r * n + s];

    for (usz i = 0; i < n; i++) {
        for (usz j = 0; j < i; j++) {
            double w = a[i * n + j];
            for (usz k = 0; k < j; k++) w = w - a[i * n + k] * a[k * n + j];
            a[i * n + j] = w / a[j * n + j];
        }
        for (usz j = i; j < n; j++) {
            double w = a[i * n + j];
            for (usz k = 0; k < i; k++) w = w - a[i * n + k] * a[k * n + j];
            a[i * n + j] = w;
        }
    }
    for (usz i = 0; i < n; i++) {
        double w = b[i];
        for (usz j = 0; j < i; j++) w = w - a[i * n + j] * y[j];
        y[i] = w;
    }
    long reverse = (long)n;
    while (reverse > 0) {
        reverse--;
        usz i = (usz)reverse;
        double w = y[i];
        for (usz j = i + 1; j < n; j++) w = w - a[i * n + j] * x[j];
        x[i] = w / a[i * n + i];
    }
    double result = 0.0;
    for (usz i = 0; i < n; i++) result += x[i];
    return result;
}
