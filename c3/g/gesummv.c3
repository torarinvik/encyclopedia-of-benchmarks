module gesummv;

const usz MAX_DIMENSION = 64;
const double INVALID_RESULT = -1e300;

fn double gesummv(long* values, ulong length) @export("gesummv") {
    if (values == null || length != 1 || values[0] < 1 || values[0] > (long)MAX_DIMENSION)
        return INVALID_RESULT;
    usz n = (usz)values[0];
    double[MAX_DIMENSION] x = {};
    for (usz i = 0; i < n; i++) x[i] = (double)(i % n) / (double)n;
    double result = 0.0;
    for (usz i = 0; i < n; i++) {
        double temporary = 0.0;
        double y = 0.0;
        for (usz j = 0; j < n; j++) {
            double a = (double)((i * j + 1) % n) / (double)n;
            double b = (double)((i * j + 2) % n) / (double)n;
            temporary = a * x[j] + temporary;
            y = b * x[j] + y;
        }
        y = 1.5 * temporary + 1.2 * y;
        result += y;
    }
    return result;
}
